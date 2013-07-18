Maestro Shell Utility Gem
=========================
[![Gem Version](https://badge.fury.io/rb/maestro_shell.png)](http://badge.fury.io/rb/maestro_shell)

Library For Executing Shell commands on Linux and Windows
=========================================================

# Introduction

This gem provides a simple class that allows shell commands to be run, with output gathered (both stdout and stderr) and
return-code availability.
Callbacks are available to deliver output in real-time as it occurs, or it may be read at the end of execution.

Important:
This gem utilizes the IO::popen4 functionality available in JRUBY.
It is not intended to work in a non-JRUBY environment.

# Installation

Add this line to your application's Gemfile:

    gem 'maestro_shell'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install maestro_shell

# Usage

In code:

    require 'shell'

## Simple single-function-call:

    result = Maestro::Util::Shell.run_command('ls')

    puts "Return Code: #{result[0]}"
    puts "Output:      #{result[1]}"

## More complete example:

This requires a delegate class/method that can read and process output as it is generated.
The signature of the delegate method should be:
    def method(text, is_stderr)

Example code:

    shell = Maestro::Util::Shell.new()
    shell.create_script('ls')
    shell.run_script_with_delegate(delegate, on_output)

    if shell.exit_code.success?
      puts 'Yay!'
    else
      puts 'Boo!!'
    end

    puts "Script exit code: #{script.exit_code.exit_code}
    puts "Entire output:    #{script}"  # or #{script.to_s}, or #{script.output}


    # The +text+ parameter is not necessarily a line of text... it could just be a "." being
    # output from a long-running process.  It could also include non-printable characters
    # as it is the raw stream from the command.
    def output_handler(text, is_stderr)
      # is_stderr is set if the text came from stderr vs normal stdout.
      # This is so you can process separately if you wish
      if is_stderr
        handle_error_text(text)
      end

      print my_logging_class.debug(text)
    end

Notes
-----

* The 'command' passed to the shell is actually written to a script file, which is then executed.  As such, it is possible to execute multi-line commands - just pass the entire string to be written to the script file as a command.
* The script file is run by the native shell on the target OS, in the case of Linux this is the bash shell, in Windows this is the default command processor.
