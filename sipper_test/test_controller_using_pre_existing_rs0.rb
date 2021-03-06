
require 'driven_sip_test_case'

# Uses default configuration option for preloaded RS
class TestControllerUsingPreExistingRs0 < DrivenSipTestCase

  def setup
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module SipInline
      class UasPeRs0Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def on_invite(session)
          logd("Received INVITE in #{name}")
          session.irequest.routes.each do |r|
            session.do_record(r.to_s)
          end
          session.respond_with(200)
        end
        
        def on_ack(session)
          session.invalidate(true)
          session.flow_completed_for("TestControllerUsingPreExistingRs0")
        end
        
        def order
          0
        end
      end
      
      class UacPeRs0Controller < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true 
        
        def start
          orig = SipperConfigurator[:PreExistingRouteSet]
          SipperConfigurator[:PreExistingRouteSet] = ["<sip:nk@sipper.com;lr>", "<sip:nk@goblet.com;lr>"]
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_initial_request("invite", "sip:nasir@sipper.com", :p_session_record=>"msg-info")
          u.send(r)
          SipperConfigurator[:PreExistingRouteSet] = orig
          logd("Sent a new INVITE from #{name}")
        end
     
        def on_success_res(session)
          logd("Received response in #{name}")
          session.request_with("ack")
          session.invalidate(true)
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("SipInline::UacPeRs0Controller")
  end
  
  
  def test_pers_controllers
    self.expected_flow = ["> INVITE", "< 100", "< 200", "> ACK"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< INVITE", "> 100", "! <sip:nk@sipper.com;lr>", "! <sip:nk@goblet.com;lr>", "> 200", "< ACK"]
    verify_call_flow(:in)
  end
  
end



