# Copyright 2011 (c) MaestroDev.  All rights reserved.

require 'tempfile'
require 'rbconfig'

module Maestro
  module Util
    class Shell

      attr_reader :script_file
      attr_reader :output_file
      attr_reader :shell
      attr_reader :exit_code

      class ExitCode
        attr_reader :exit_code

        def initialize(status)
          @exit_code = status.exitstatus
        end

        def success?
          @exit_code == 0
        end
      end

      # Utility variables
      IS_WINDOWS         = RbConfig::CONFIG['host_os'] =~ /mswin/
      SEPARATOR          = IS_WINDOWS ? "\\" : "/"
      MOVE_COMMAND       = IS_WINDOWS ? 'move' : 'mv'
      ENV_EXPORT_COMMAND = IS_WINDOWS ? 'set' : 'export'
      COMMAND_SEPARATOR  = '&&' # IS_WINDOWS ? '&&' : '&&'
      SCRIPT_EXTENSION   = IS_WINDOWS ? '.bat' : '.shell'
      SHELL_EXECUTABLE   = IS_WINDOWS ? '' : 'bash '
      COMMAND_SUFFIX     = IS_WINDOWS ? '' : ' 2>&1 | tee'

      def Shell.unset_env_variable(var)
        IS_WINDOWS ? "set #{var}=" : "unset #{var}"
      end

      def Shell.run_command(command)
        shell = Shell.new
        shell.create_script(command)
        shell.run_script
        return shell.exit_code, shell.to_s
      end

      def create_script(contents)
        raise "Script Cannot Be Empty" if contents.nil? or contents.empty?

        @script_file = Tempfile.new(["script", SCRIPT_EXTENSION])
        @output_file = Tempfile.new(['output','log'])
        # Run any commands in the default system Ruby environment, rather
        # than the one the agent is currently using (which within the wrapper,
        # sets clean values for these to avoid RVM or System gems that might
        # conflict). If the caller needs a specific Ruby environment, it should
        # establish that itself (as the rake task does through rvm if chosen)
        # Add clear env variable commands to head of script, since we don't necessarily have access to env here (depending on
        # version of ruby/bugs)
        contents = "#{Shell.unset_env_variable('GEM_HOME')}\n#{Shell.unset_env_variable('GEM_PATH')}\n#{contents}"
        @script_file.write(contents)
        @script_file.close
        Maestro.log.debug "Writing Script File To #{@script_file.path}"
        return get_command(@script_file.path)
      end

      def run_script
        run_script_with_delegate(nil, nil)
      end

      # if +delegate+ provided, the method named/symbolized by +on_output+ value will be called for each line
      # of output to either stdout or stderr.
      # two parameters are passed:
      #   +text+  String  Output text.  This may be any amount of data from 1 character to many lines.
      #                   do not assume it always represents a single line.
      #   +err+   Boolean True if line is from stderr
      def run_script_with_delegate(delegate, on_output)
        File.open(@output_file.path, 'a') do |out_file|
          status = IO.popen4(@command_line) do |pid, stdin, stdout, stderr|
            # Keep reading input until all (stdin/stderr) streams report eof
            readers = [stdout, stderr]
            while readers.any?
              ready = IO.select(readers, [], readers)
              # no writers
              # ready[1].each { ... }
              ready[0].each do |fd|
                if fd.eof?
                  readers.delete fd
                 else

                  text = fd.readpartial(1024)
                  out_file.write(text)

                  if delegate && on_output
                    delegate.send(on_output, text)
                  end
                end
              end
            end
          end
        end

        @exit_code = ExitCode.new($?)

        return @exit_code
      end

      def to_s
        @output_file.read if @output_file
      end
      alias :output :to_s

      ###########
      # PRIVATE #
      ###########

      private
      
      def get_command(path)
        @command_line = "#{SHELL_EXECUTABLE}#{path}#{COMMAND_SUFFIX}"
        @command_line
      end

    end
  end
end
