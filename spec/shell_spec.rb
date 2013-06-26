require 'spec_helper'

describe Maestro::Util::Shell do
  
  # it 'should create a script' do
  #   path = subject.create_script "some shell command"
  #   
  #   File.exists?(path).should be_true
  # end

  # it 'should create a script without random path' do
  #   subject = Maestro::Util::Shell.new("/tmp/maestro-test-script")
  #   path = subject.create_script "some shell command"
  #   subject.shell.should eql("/bin/bash")
  #   File.exists?(path).should be_true
  # end

  # it 'should create a script with shell parameter' do
  #   subject = Maestro::Util::Shell.new(nil, "/tmp/bash")
  #   path = subject.create_script "some shell command"
  #   File.exists?(path).should be_true
  #   path.should_not eql("/tmp/bash")
  # end
  # 
  # it 'should create two scripts with random name' do
  #   path1 = subject.create_script "some shell command"
  #   path2 = subject.create_script "another shell command"
  # 
  #   path1.should_not eql(path2)
  #   File.exists?(path1).should be_true
  #   File.exists?(path2).should be_true
  # end

  it 'should run script' do
    path = subject.create_script "echo willy"
    # File.exists?(path).should be_true
    
    subject.run_script.success?.should be_true
    
    subject.to_s.chomp.should eql('willy')
  end
  
  it 'should run script with delegate' do
     path = subject.create_script "echo willy"
     
     delegate = mock()
     delegate.expects(:write_output).at_least(1)
     
     subject.run_script_with_delegate(delegate, "write_output")
     subject.to_s.chomp.should eql('willy')
   end

   it 'should parse output' do
     path = subject.create_script "echo wonka"
   
     
     subject.run_script
     subject.to_s.chomp.should eql("wonka")
   end

   it 'should return error on error' do
     path = subject.create_script "blah hello"
     
     subject.run_script.success?.should be_false
     subject.to_s.should include("blah: command not found")
   end

   it 'should run with with export inline' do
     command =<<-CMD
#{Maestro::Util::Shell::ENV_EXPORT_COMMAND} BLAH=blah; echo $BLAH
     CMD
     
     path = subject.create_script command
     
     subject.run_script.success?.should be_true
     subject.to_s.should eql("blah\n")
   end


   it 'should run multiline command' do
     command =<<-CMD
echo hello\r\n
echo goodbye     
     CMD
     
     path = subject.create_script command
     
     subject.run_script.success?.should be_true
     subject.to_s.should eql("hello\r\ngoodbye\n")
   end

   it 'should create run and return result in on call' do
     exit_code, output = Maestro::Util::Shell.run_command('echo what')
     output.should eql("what\n")
     exit_code.success?.should be_true
   end

   it 'should maintain env' do
     temp = Tempfile.new('script.sh')
     temp.write("echo $BLAH")
     temp.close
     File.chmod(0777, temp.path)
     command =<<-CMD
#{Maestro::Util::Shell::ENV_EXPORT_COMMAND} BLAH=blah; echo $BLAH
#{temp.path}
     CMD

     path = subject.create_script command
     
     subject.run_script.success?.should be_true
     subject.to_s.should eql("blah\nblah\n")
     
     temp = Tempfile.new('script.sh')
     temp.write("pwd")
     temp.close
     File.chmod(0777, temp.path)
     command =<<-CMD
     pwd
     cd /
#{temp.path}
     CMD

     path = subject.create_script command
     
     subject.run_script.success?.should be_true
     subject.to_s.should eql("#{`pwd`}/\n")
   end
   
   it "should load all of a large output" do
      output =`cat #{File.join(File.dirname(__FILE__), '..','maestro_shell.gemspec')}`.chomp
      subject.create_script "cat #{File.join(File.dirname(__FILE__), '..','maestro_shell.gemspec')}"
      
      subject.run_script
      subject.to_s.chomp.should eql(output)
  end
end
