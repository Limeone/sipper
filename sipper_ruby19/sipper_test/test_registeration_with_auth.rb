

require 'driven_sip_test_case'

class TestRegisterationWithAuth < DrivenSipTestCase

  def setup
    SipperConfigurator[:ProtocolCompliance] = 'strict'
    super
    str = <<-EOF
    require 'sip_test_driver_controller'
    module TestRegistrationController_SipInline
      class UasAuthRegistrarController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        realm "my_sipper.com"
        authenticate_requests :register
        use_compact_headers :all_headers
        def on_register(session)
          logd("Received REGISTER in "+name)
          r = session.create_response(200, "OK") 
          r.to.tag = "my_new_tag"
          registration_store.put(:test, session.irequest.contact.uri.to_s)   
          session.send(r)
          session.invalidate(true)
        end
        
        
        def order
          0
        end
      end
      
      class UacAuthRegisterController < SIP::SipTestDriverController
      
        transaction_usage :use_transactions=>true
        
        def start
          u = create_udp_session(SipperConfigurator[:LocalSipperIP], SipperConfigurator[:LocalTestPort])
          r = u.create_register_request("sip:sipper.com", "sip:bob@sipper.com", "sip:bob@192.168.1.2")
          r.p_session_record="msg-info"
          u.send(r)
          logd("Sent a new REGISTER from "+name)
        end
     
        def on_success_res(session)
          logd("Received response in "+name)
          session.do_record(registration_store.get(:test))
          session.invalidate(true)
          session.flow_completed_for("TestRegisterationWithAuth")
        end
        
        def on_failure_res(session)
          if session.iresponse.code == 401
            r = session.create_request_with_response_to_challenge(session.iresponse.www_authenticate, false,
                 "sipper_user", "sipper_passwd")     
            session.send r
          end
        end
        
      end
    end
    EOF
    define_controller_from(str)
    set_controller("TestRegistrationController_SipInline::UacAuthRegisterController")
  end
  
  
  def test_registration
    self.expected_flow = ["> REGISTER", "< 401", "> REGISTER", "< 200", "! sip:bob@192.168.1.2"]
    start_controller
    verify_call_flow(:out)
    self.expected_flow = ["< REGISTER", "> 401", "< REGISTER", "> 200" ]
    verify_call_flow(:in)
  end
  
  def teardown
    SIP::Locator[:RegistrationStore].destroy
    super
  end
  
end