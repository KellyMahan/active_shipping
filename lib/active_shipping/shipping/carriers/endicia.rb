module ActiveMerchant
  module Shipping
    class Endicia < Carrier
      
      self.retry_safe = true
      
      cattr_accessor :default_options
      cattr_reader :name
      attr_accessor :client
      @@name = "Endicia"
      CONFIG_NAME="endicia"
            
      LIVE_URL = TEST_URL = 'https://www.envmgr.com/LabelService/EwsLabelService.asmx'
      #LIVE_URL = 'https://LabelServer.endicia.com/LabelService/EwsLabelService.asmx'
      
      LIVE_URL_REFUND = TEST_URL_REFUND = 'https://www.endicia.com/ELS/ELSServices.cfc?wsdl'
      #LIVE_URL_REFUND = 'https://www.endicia.com/ELS/ELSServices.cfc?wsdl'
      
      
      RESOURCES = {
        :GetPostageLabelXML => 'GetPostageLabelXML',
        :CalculatePostageRateXML => 'CalculatePostageRateXML',
        :BuyPostageXML => 'BuyPostageXML',
        :ChangePassPhraseXML => 'ChangePassPhraseXML',
        :GetAccountStatusXML => 'GetAccountStatusXML',
        :RefundRequest => 'RefundRequest',
        :PickupRequest => 'CarrierPickupRequest'
      }
      
      XMLKEY = {
        :GetPostageLabelXML => 'labelRequestXML',
        :CalculatePostageRateXML => 'postageRateRequestXML',
        :BuyPostageXML => 'recreditRequestXML',
        :ChangePassPhraseXML => 'changePassPhraseRequestXML',
        :GetAccountStatusXML => 'accountStatusRequestXML',
        :RefundRequest => 'XMLInput',
        :PickupRequest => 'XMLInput'
      }
      
      US_SERVICES = {
        :first_class => 'First',
        :priority => 'Priority',
        :express => 'Express'
      }
      
      FLAT_RATES = {
        :Priority => {
          :FlatRateEnvelope => ['USPS - Priority Mail Flat Rate Envelope', 4.75],
          :SmallFlatRateBox => ['USPS  - Priority Mail Small Flat Rate Box', 4.85],
          :MediumFlatRateBox => ['USPS  - Priority Mail Medium Flat Rate Box', 10.20],
          :LargeFlatRateBox => ['USPS  - Priority Mail Large Flat Rate Box', 13.95]
        },
        :Express => {
          :FlatRateEnvelope => ['USPS  - Express Mail Small Flat Rate Envelope', 17.40]
        }
      }

      
      def requirements
        [:request_id, :requester_id, :account_id, :pass_phrase]
      end
      
      def create_shipping_label(shipment_object, options={})
        options = @options.update(options)
        shipping_label_request = build_shipping_label_request(shipment_object, options)
        response = commit(:GetPostageLabelXML, shipping_label_request, (options[:test] || false))
        return response
      end
      
      def find_rates(shipment_object, options={})
        options = @options.update(options)
        shipping_rate_request = build_postage_rate_request(shipment_object, options)
        response = commit(:CalculatePostageRateXML, shipping_rate_request, (options[:test] || false))
        return response
      end
      
      def buy_postage(amount, options={})
        options.merge!({:request_id=>"#{DateTime.now}"})
        options = @options.update(options)
        buy_postage_request = build_buy_postage_request(amount, options)
        response = commit(:BuyPostageXML, buy_postage_request, (options[:test] || false))
        return response
      end
      
      def request_refund(tracking_number, options={})
        options = @options.update(options)
        refund_request = build_refund_request(tracking_number, options)
        response = refund_commit(:RefundRequest, refund_request, (options[:test] || false))
        return response
      end
      
      
      def request_pickup(shipment, options={})
        options = @options.update(options)
        pickup_request = build_pickup_request(shipment, options)
        response = pickup_commit(:PickupRequest, pickup_request, (options[:test] || false))
        return response
      end
      
      def change_pass_phrase(pass, options={})
        options = @options.update(options)
        change_pass_request = build_change_pass_request(pass, options)
        response = commit(:ChangePassPhraseXML, change_pass_request, (options[:test] || false))
        return response
      end
      
      def postage_balance(options={})
        options.merge!({:request_id=>"#{DateTime.now}"})
        doc = Hpricot(self.account_status(options))
        return (doc/:postagebalance).inner_text.to_f
      end
      
      def account_status(options={})
        options = @options.update(options)
        account_status_request = build_account_status_request(options)
        response = commit(:GetAccountStatusXML, account_status_request, (options[:test] || false))
        return response
      end
      
      private
      
      def build_account_status_request(options={})
        xml_request = XmlNode.new('AccountStatusRequest') do |root_node|
          root_node << XmlNode.new('RequesterID', @options[:requester_id])
          root_node << XmlNode.new('RequestID', @options[:request_id])
          root_node << XmlNode.new('CertifiedIntermediary') do |ci|
            ci << XmlNode.new('AccountID', @options[:account_id])
            ci << XmlNode.new('PassPhrase', @options[:pass_phrase])
          end
        end
        save_request(xml_request.to_s)
      end
      
      def build_change_pass_request(pass,options={})
        xml_request = XmlNode.new('ChangePassPhraseRequest') do |root_node|
          root_node << XmlNode.new('RequesterID', @options[:requester_id])
          root_node << XmlNode.new('RequestID', @options[:request_id])
          root_node << XmlNode.new('CertifiedIntermediary') do |ci|
            ci << XmlNode.new('AccountID', @options[:account_id])
            ci << XmlNode.new('PassPhrase', @options[:pass_phrase])
          end
          root_node << XmlNode.new('NewPassPhrase', pass)
        end
        save_request(xml_request.to_s)
      end
      
      def build_buy_postage_request(amount, options={})
        xml_request = XmlNode.new('RecreditRequest') do |root_node|
          root_node << XmlNode.new('RequesterID', @options[:requester_id])
          
          root_node << XmlNode.new('RequestID', @options[:request_id])
          root_node << XmlNode.new('CertifiedIntermediary') do |ci|
            ci << XmlNode.new('AccountID', @options[:account_id])
            ci << XmlNode.new('PassPhrase', @options[:pass_phrase])
          end
          root_node << XmlNode.new('RecreditAmount', amount)
        end
        save_request(xml_request.to_s)
      end
      
      def build_pickup_request(shipment, options={})
        tracking_number = options[:tracking_number]
        xml_request = XmlNode.new('CarrierPickupRequest') do |root_node|
          root_node << XmlNode.new('AccountID', @options[:account_id])
          root_node << XmlNode.new('PassPhrase', @options[:pass_phrase])
          root_node << XmlNode.new('Test', "Y") if @options[:test]
          
          
          root_node << XmlNode.new('FirstName')
          root_node << XmlNode.new('LastName')
          root_node << XmlNode.new('CompanyName', shipment.shipper.name)
          
          root_node << XmlNode.new('Address', shipment.shipper.address1)
          root_node << XmlNode.new('SuiteOrApt', shipment.shipper.address2)
          root_node << XmlNode.new('City', shipment.shipper.city)
          root_node << XmlNode.new('State', shipment.shipper.province)
          
          if shipment.shipper.postal_code.match(/-/)
            zip5 = shipment.shipper.postal_code.split(/-/)[0]
            zip4 = shipment.shipper.postal_code.split(/-/)[1]
          else
            zip5 = shipment.shipper.postal_code
            zip4 = nil
          end
          
          root_node << XmlNode.new('ZIP5', zip5)
          root_node << XmlNode.new('ZIP4', zip4)
          
          root_node << XmlNode.new('Phone', shipment.shipper.phone.gsub(/[^0-9]/,""))
          
          root_node << XmlNode.new('PickupList') do |refund_list|
            if tracking_number.is_a?(Array)
              tracking_number.each do |tn|
                refund_list << XmlNode.new('PICNumber', tn)
              end
            else
              refund_list << XmlNode.new('PICNumber', tracking_number)
            end
          end
          
        end
        save_request(xml_request.to_s)
      end
      
      def build_refund_request(tracking_number, options={})
        xml_request = XmlNode.new('RefundRequest') do |root_node|
          root_node << XmlNode.new('AccountID', @options[:account_id])
          root_node << XmlNode.new('PassPhrase', @options[:pass_phrase])
          root_node << XmlNode.new('Test', "Y") if @options[:test]
          
          root_node << XmlNode.new('RefundList') do |refund_list|
            if tracking_number.is_a?(Array)
              tracking_number.uniq.each do |tn|
                refund_list << XmlNode.new('PICNumber', tn)
              end
            else
              refund_list << XmlNode.new('PICNumber', tracking_number)
            end
          end
          
        end
        save_request(xml_request.to_s)
      end
      
      def build_postage_rate_request(shipment, options={})
        
        # label_requests = shipment.packages.map do |package|
          package = shipment.packages[0]
          #xml_request = XmlNode.new('LabelRequest', :Test=> "YES", :LabelType => "Default", :LabelSize=>"4X6", :ImageFormat=>"ZPLII") do |root_node|
          xml_request = XmlNode.new('PostageRateRequest') do |root_node|
            root_node << XmlNode.new('RequesterID', @options[:requester_id])
            root_node << XmlNode.new('CertifiedIntermediary') do |ci|
              ci << XmlNode.new('AccountID', @options[:account_id])
              ci << XmlNode.new('PassPhrase', @options[:pass_phrase])
            end

            root_node << XmlNode.new('FromPostalCode', shipment.shipper.postal_code)
            if shipment.ship_to.postal_code.match(/-/)
              zip5 = shipment.ship_to.postal_code.split(/-/)[0]
            else
              zip5 = shipment.ship_to.postal_code
            end
            root_node << XmlNode.new('ToPostalCode', zip5)
            root_node << XmlNode.new('WeightOz', package.ounces)
            root_node << XmlNode.new('MailpieceShape', package.package_type)
            root_node << XmlNode.new('MailClass', shipment.service_type_code)
            root_node << XmlNode.new('MailpieceDimensions') do |mpd|
              mpd << XmlNode.new('Length', package.inches[0])
              mpd << XmlNode.new('Width', package.inches[1])
              mpd << XmlNode.new('Height', package.inches[2])
            end
            if shipment.service_type_code == 'Express'
              root_node << XmlNode.new('SundayHolidayDelivery', "FALSE")
            end

            root_node << XmlNode.new('ResponseOptions', :PostagePrice => "TRUE")
            
          end
          save_request(xml_request.to_s)
        
        
      end
      
      def build_shipping_label_request(shipment, options={})
        
        # label_requests = shipment.packages.map do |package|
          package = shipment.package
          #xml_request = XmlNode.new('LabelRequest', :Test=> "YES", :LabelType => "Default", :LabelSize=>"4X6", :ImageFormat=>"ZPLII") do |root_node|
          xml_request = XmlNode.new('LabelRequest', :LabelType => "Default", :LabelSize=>"4X6", :ImageFormat=>@options[:print_method_code]) do |root_node|
            root_node << XmlNode.new('RequesterID', @options[:requester_id])
            root_node << XmlNode.new('AccountID', @options[:account_id])
            root_node << XmlNode.new('PassPhrase', @options[:pass_phrase])
            root_node << XmlNode.new('PartnerCustomerID', @options[:partner_customer_id])
            root_node << XmlNode.new('PartnerTransactionID', shipment.reference_number)
            
            
            if (shipment.shipper.attention_name ? shipment.shipper.attention_name.empty? : nil)
              root_node << XmlNode.new('FromName', shipment.shipper.name)
              root_node << XmlNode.new('FromCompany', '')
            else
              root_node << XmlNode.new('FromName', shipment.shipper.attention_name)
              root_node << XmlNode.new('FromCompany', shipment.shipper.name)
            end
            root_node << XmlNode.new('ReturnAddress1', shipment.shipper.address1)
            root_node << XmlNode.new('ReturnAddress2', shipment.shipper.address2)
            root_node << XmlNode.new('FromCity', shipment.shipper.city)
            root_node << XmlNode.new('FromState', shipment.shipper.province)
            root_node << XmlNode.new('FromPostalCode', shipment.shipper.postal_code)
            root_node << XmlNode.new('FromPhone', (shipment.shipper.phone.gsub(/[^0-9]/,"") rescue nil))
          
            if (shipment.shipper.attention_name ? shipment.shipper.attention_name.empty? : nil)
              root_node << XmlNode.new('ToName', shipment.ship_to.name)
              root_node << XmlNode.new('ToCompany')
            else
              root_node << XmlNode.new('ToName', shipment.ship_to.attention_name)
              root_node << XmlNode.new('ToCompany', shipment.ship_to.name)
            end
            root_node << XmlNode.new('ToAddress1', shipment.ship_to.address1)
            root_node << XmlNode.new('ToAddress2', shipment.ship_to.address2)
            root_node << XmlNode.new('ToCity', shipment.ship_to.city)
            root_node << XmlNode.new('ToState', shipment.ship_to.province)
            
            if shipment.ship_to.postal_code.match(/-/)
              zip5 = shipment.ship_to.postal_code.split(/-/)[0]
              zip4 = shipment.ship_to.postal_code.split(/-/)[1]
            else
              zip5 = shipment.ship_to.postal_code
              zip4 = nil
            end
            root_node << XmlNode.new('ToPostalCode', zip5)
            root_node << XmlNode.new('ToZIP4', zip4)
            
            root_node << XmlNode.new('WeightOz', package.ounces)
            root_node << XmlNode.new('MailpieceShape', package.package_type)
            root_node << XmlNode.new('MailClass', shipment.service_type_code)
            root_node << XmlNode.new('MailpieceDimensions') do |mpd|
              mpd << XmlNode.new('Length', package.inches[0])
              mpd << XmlNode.new('Width', package.inches[1])
              mpd << XmlNode.new('Height', package.inches[2])
            end
            if shipment.service_type_code == 'Express'
              #root_node << XmlNode.new('ServiceLevel', shipment.service_type_code)
              root_node << XmlNode.new('SundayHolidayDelivery', "FALSE")
            end
            
            root_node << XmlNode.new('ShowReturnAddress', "TRUE")
            root_node << XmlNode.new('Stealth', "TRUE")
            root_node << XmlNode.new('Description', shipment.description)
            root_node << XmlNode.new('RubberStamp1', 'Order:')
            root_node << XmlNode.new('RubberStamp2', "##{shipment.order_id}")
            # root_node << XmlNode.new('RubberStamp3', 'Thank You')
            root_node << XmlNode.new('POZipCode', shipment.po_zip_code)
            root_node << XmlNode.new('ResponseOptions', :PostagePrice => "TRUE")
            if shipment.check_for_customs  #needed for customs
              root_node << XmlNode.new('Value', shipment.value)
              root_node << XmlNode.new('CustomsFormType', 'Form2976A') 
              root_node << XmlNode.new('CustomsFormImageFormat', 'PDF')
              root_node << XmlNode.new('OriginCountry', 'United States')
              root_node << XmlNode.new('ContentsType', 'Gift')
              if shipment.signed_by
                root_node << XmlNode.new('CustomsCertify', "TRUE")
                root_node << XmlNode.new('CustomsSigner', shipment.signed_by)
                root_node << XmlNode.new('CustomsDescription1', shipment.description)
                root_node << XmlNode.new('CustomsQuantity1', shipment.quantity)
                root_node << XmlNode.new('CustomsWeight1', package.ounces.to_i.to_s)
                root_node << XmlNode.new('CustomsValue1', shipment.value)
                root_node << XmlNode.new('CustomsCountry1', 'United States')
                root_node << XmlNode.new('NonDeliveryOption','Return')
                root_node << XmlNode.new('ToPhone',shipment.ship_to.phone.gsub(/[^\d]/,''))
              end
            end
              
            
          end
          save_request(xml_request.to_s)
        # end
      end
      
      def refund_commit(action, request, test = false)
        ssl_post("#{test ? TEST_URL_REFUND : LIVE_URL_REFUND}", "&method=RefundRequest&#{XMLKEY[action]}=#{CGI.escape(request)}")
      end

      def pickup_commit(action, request, test = false)
        ssl_post("#{test ? TEST_URL_REFUND : LIVE_URL_REFUND}", "&method=CarrierPickupRequest&#{XMLKEY[action]}=#{CGI.escape(request)}")
      end
      
      def commit(action, request, test = false)

        ssl_post("#{test ? TEST_URL : LIVE_URL}/#{RESOURCES[action]}", "#{XMLKEY[action]}=#{CGI.escape(request)}")
      end
      
    end
  end
end