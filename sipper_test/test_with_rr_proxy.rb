
require 'driven_sip_test_case'


class TestWithRRProxy < DrivenSipTestCase
  
  # To run this test in windows, in a separate shell execute the proxy 
  # "srun -p 5068 -0 5067 -c nonrr_proxy.rb"
  # and set an env var 
  # "set SIPPER_TEST_PROXY_EXTERNAL=true"
  # You would do similar thing for rr_proxy with a higher port in a second shell
  # "srun -p 5069 -0 5067 -c rr_proxy.rb"
  # Let these two proxies run.
  # Then run the test cases, after you are done make sure to unset the env var by
  # "set SIPPER_TEST_PROXY_EXTERNAL="
  # For one run you need only to execute the two proxies only once for all tests. 
  def setup
    @sr = SipperConfigurator[:SessionRecord] 
    SipperConfigurator[:SessionRecord] = "msg-info"
    @tp = SipperConfigurator[:LocalTestPort]
    SipperConfigurator[:LocalTestPort] = 5067
    SipperConfigurator[:SessionRecord] = "msg-info"
    super
    unless RUBY_PLATFORM =~ /mswin/
      system("srun -p #{SipperConfigurator[:LocalTestPort]+2} -o #{SipperConfigurator[:LocalTestPort]} -rf 3 -c #{File.join(File.dirname(__FILE__), "rr_proxy.rb")} &")    
    end
    
    str2 = <<-EOF2
    
    require 'sip_test_driver_controller'
    
    module SipInline
      class UasRt2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          if session.irequest[:via].length == 2
            session.do_record("double_via")
          end
          session.respond_with(200)
          logd("Received INVITE sent a 200 from "+name)
        end
        
        def on_ack(session)
          session.request_with("bye")
        end
        
        def on_success_res(session)
          session.invalidate(true)
          session.flow_completed_for("TestWithRRProxy")
        end
        
        def order
          0
        end
        
      end
      
      class UacRt2Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true  
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort]+2)
          r = u.create_initial_request("invite", "sip:nasir@sipper.com")
          u.send(r)
          logd("Sent a new INVITE from "+name)
        end
     
        
        def on_success_res(session)
          session.request_with('ACK')
        end
        
        def on_bye(session)
          if session.irequest[:via].length == 2
            session.do_record("double_via")
          end
          session.respond_with(200)
          session.invalidate(true)
        end
         
      end
    end
    EOF2
    define_controller_from(str2)
    set_controller("SipInline::UacRt2Controller")
  end
  
  
  def test_rt1_controllers
    if RUBY_PLATFORM =~ /mswin/ && !ENV['SIPPER_TEST_PROXY_EXTERNAL'] 
      return  
    end
    self.expected_flow = ["> INVITE {1,}", "< 100", "< 200", "> ACK", "< BYE", "! double_via", "> 200"]
    start_controller
    sleep 3
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! double_via", "> 200", "< ACK", "> BYE", "< 200"]
    verify_call_flow(:in)
  end
  
  def teardown
    SipperConfigurator[:SessionRecord] = @sr
    SipperConfigurator[:LocalTestPort] = @tp
    super
  end

end

