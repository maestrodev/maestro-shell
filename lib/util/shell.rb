# Copyright 2011 (c) MaestroDev.  All rights reserved.

require 'childprocess'
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
          @exit_code = status
        end

        def success?
          @exit_code == 0
        end
      end

      # Utility variables
      IS_WINDOWS         = ChildProcess.windows?
      SEPARATOR          = IS_WINDOWS ? "\\" : "/"
      MOVE_COMMAND       = IS_WINDOWS ? 'move' : 'mv'
      ENV_EXPORT_COMMAND = IS_WINDOWS ? 'set' : 'export'
      COMMAND_SEPARATOR  = '&&' # IS_WINDOWS ? '&&' : '&&'
      SCRIPT_EXTENSION   = IS_WINDOWS ? '.bat' : '.shell'
      BASH_EXECUTABLE    = 'bash'

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
          r, w = IO.pipe
          ChildProcess.posix_spawn = true
          if IS_WINDOWS
            if ChildProcess.jruby?
              # Due to https://github.com/jarib/childprocess/issues/26, we
              # must use a different implementation of ChildProcess on
              # Windows + JRuby
              process = ChildProcess::JRuby::Process.new([@command_line])
            else
              process = ChildProcess.build(@command_line)
            end
          else
            process = ChildProcess.build(BASH_EXECUTABLE, @command_line)
          end
          process.io.stdout = process.io.stderr = w
          process.start
          # On Windows, can't close the pipe until process has exited or you
          # get an EOF, see
          # https://github.com/jarib/childprocess/pull/22#issuecomment-3395687
          w.close unless IS_WINDOWS

          potential_eof = false
          begin
            loop {
              text = r.read_nonblock(1024)
              potential_eof = false
              out_file.write(text)

              if delegate && on_output
                delegate.send(on_output, text)
              end
            }
          rescue IO::WaitReadable => e
            if !process.exited?
              # process still running, block for input here to avoid a busy
              # loop, but with a timeout in case the process exited with no
              # further output
              IO.select([r], nil, nil, 1)
              retry
            elsif !potential_eof
              # process is done, but keep looping while there is input to
              # read
              potential_eof = true
              retry
            end
          rescue EOFError
            # expected when we reach end of output from the process
          end

          r.close
          process.wait unless process.exited?
          w.close if IS_WINDOWS
          @exit_code = ExitCode.new(process.exit_code)
        end

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
        @command_line = path
        @command_line
      end

    end
  end
end
