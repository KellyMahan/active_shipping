# FedEx module by Jimmy Baker
# http://github.com/jimmyebaker

module ActiveMerchant
  module Shipping
    
    # :key is your developer API key
    # :password is your API password
    # :account is your FedEx account number
    # :login is your meter number
    class FedEx < Carrier
      self.retry_safe = true
      
      cattr_reader :name
      @@name = "FedEx"
      attr_accessor :response
      
      TEST_URL = 'https://wsbeta.fedex.com:443/xml'
      LIVE_URL = 'https://ws.fedex.com:443/xml'
      DECLARATION_STATEMENT = 'I hereby certify that the information on this invoice is true and correct and the contents and value of this shipment is as stated above.'
      ETD_COUNTRIES = ['AF', 'AL', 'AU', 'AT', 'BH', 'BB', 'BE', 'BM', 'CA', 'GB', 'CN', 'HR', 'CY', 'CZ', 'DK', 'EE', 'FI', 'FR', 'DE', 'HK', 'HU', 'IS', 'IN',
                       'IE', 'IL', 'IT', 'JP', 'KR', 'LV', 'LI', 'LT', 'LU', 'MO', 'MY', 'MX', 'MC', 'NL', 'NZ', 'NO', 'PS', 'PH', 'PL', 'PT', 'PR', 'SM', 'SG',
                       'SK', 'SI', 'ZA', 'ES', 'SE', 'CH', 'TH', 'TW', 'US' ]
      NUMBER_OF_RATE_REQUEST_TRIES = 2

      
      ServiceTypes = {
        "PRIORITY_OVERNIGHT"                       => "FedEx Priority Overnight",
        "PRIORITY_OVERNIGHT_SATURDAY_DELIVERY"     => "FedEx Priority Overnight Saturday Delivery",
        "FEDEX_2_DAY"                              => "FedEx 2 Day",
        "FEDEX_2_DAY_SATURDAY_DELIVERY"            => "FedEx 2 Day Saturday Delivery",
        "STANDARD_OVERNIGHT"                       => "FedEx Standard Overnight",
        "FIRST_OVERNIGHT"                          => "FedEx First Overnight",
        "FIRST_OVERNIGHT_SATURDAY_DELIVERY"        => "FedEx First Overnight Saturday Delivery",
        "FEDEX_EXPRESS_SAVER"                      => "FedEx Express Saver",
        "FEDEX_1_DAY_FREIGHT"                      => "FedEx 1 Day Freight",
        "FEDEX_1_DAY_FREIGHT_SATURDAY_DELIVERY"    => "FedEx 1 Day Freight Saturday Delivery",
        "FEDEX_2_DAY_FREIGHT"                      => "FedEx 2 Day Freight",
        "FEDEX_2_DAY_FREIGHT_SATURDAY_DELIVERY"    => "FedEx 2 Day Freight Saturday Delivery",
        "FEDEX_3_DAY_FREIGHT"                      => "FedEx 3 Day Freight",
        "FEDEX_3_DAY_FREIGHT_SATURDAY_DELIVERY"    => "FedEx 3 Day Freight Saturday Delivery",
        "INTERNATIONAL_PRIORITY"                   => "FedEx International Priority",
        "INTERNATIONAL_PRIORITY_SATURDAY_DELIVERY" => "FedEx International Priority Saturday Delivery",
        "INTERNATIONAL_ECONOMY"                    => "FedEx International Economy",
        "INTERNATIONAL_FIRST"                      => "FedEx International First",
        "INTERNATIONAL_PRIORITY_FREIGHT"           => "FedEx International Priority Freight",
        "INTERNATIONAL_ECONOMY_FREIGHT"            => "FedEx International Economy Freight",
        "GROUND_HOME_DELIVERY"                     => "FedEx Ground Home Delivery",
        "FEDEX_GROUND"                             => "FedEx Ground",
        "INTERNATIONAL_GROUND"                     => "FedEx International Ground"
      }
      
      PackageIdentifierTypes = {
        'tracking_number'           => 'TRACKING_NUMBER_OR_DOORTAG',
        'door_tag'                  => 'TRACKING_NUMBER_OR_DOORTAG',
        'rma'                       => 'RMA',
        'ground_shipment_id'        => 'GROUND_SHIPMENT_ID',
        'ground_invoice_number'     => 'GROUND_INVOICE_NUMBER',
        'ground_customer_reference' => 'GROUND_CUSTOMER_REFERENCE',
        'ground_po'                 => 'GROUND_PO',
        'express_reference'         => 'EXPRESS_REFERENCE',
        'express_mps_master'        => 'EXPRESS_MPS_MASTER'
      }

      TransitTimes = {
        "TWENTY_DAYS"    => 20,
        "NINETEEN_DAYS"  => 19,
        "EIGHTEEN_DAYS"  => 18,
        "SEVENTEEN_DAYS" => 17,
        "SIXTEEN_DAYS"   => 16,
        "FIFTEEN_DAYS"   => 15,
        "FOURTEEN_DAYS"  => 14,
        "THIRTEEN_DAYS"  => 13,
        "ELEVEN_DAYS"    => 11,
        "TWELVE_DAYS"    => 12, 
        "TEN_DAYS"       => 10,
        "NINE_DAYS"      => 9,
        "EIGHT_DAYS"     => 8,
        "SEVEN_DAYS"     => 7,
        "SIX_DAYS"       => 6, 
        "FIVE_DAYS"      => 5,
        "FOUR_DAYS"      => 4,
        "THREE_DAYS"     => 3,
        "TWO_DAYS"       => 2,
        "ONE_DAY"        => 1,
        "UNKNOWN"        => 100
      }
      
      MaxTransitTimes = {
        "PRIORITY_OVERNIGHT"                       => "ONE_DAY",
        "PRIORITY_OVERNIGHT_SATURDAY_DELIVERY"     => "ONE_DAY",
        "FEDEX_2_DAY"                              => "TWO_DAYS",
        "FEDEX_2_DAY_AM"                           => "TWO_DAYS",
        "FEDEX_2_DAY_SATURDAY_DELIVERY"            => "TWO_DAYS",
        "STANDARD_OVERNIGHT"                       => "ONE_DAY",
        "FIRST_OVERNIGHT"                          => "ONE_DAY",
        "FIRST_OVERNIGHT_SATURDAY_DELIVERY"        => "ONE_DAY",
        "FEDEX_EXPRESS_SAVER"                      => "THREE_DAYS",
        "FEDEX_1_DAY_FREIGHT"                      => "ONE_DAY",
        "FEDEX_1_DAY_FREIGHT_SATURDAY_DELIVERY"    => "ONE_DAY",
        "FEDEX_2_DAY_FREIGHT"                      => "TWO_DAYS",
        "FEDEX_2_DAY_FREIGHT_SATURDAY_DELIVERY"    => "TWO_DAYS",
        "FEDEX_3_DAY_FREIGHT"                      => "THREE_DAYS",
        "FEDEX_3_DAY_FREIGHT_SATURDAY_DELIVERY"    => "THREE_DAYS",
        "INTERNATIONAL_PRIORITY"                   => "THREE_DAYS",
        "INTERNATIONAL_PRIORITY_SATURDAY_DELIVERY" => "THREE_DAYS",
        "INTERNATIONAL_ECONOMY"                    => "FIVE_DAYS",
        "INTERNATIONAL_FIRST"                      => "THREE_DAYS",
        "INTERNATIONAL_PRIORITY_FREIGHT"           => "THREE_DAYS",
        "INTERNATIONAL_ECONOMY_FREIGHT"            => "FIVE_DAYS",
        "GROUND_HOME_DELIVERY"                     => "SEVEN_DAYS",
        "FEDEX_GROUND"                             => "SEVEN_DAYS",
        "INTERNATIONAL_GROUND"                     => "SEVEN_DAYS"
      }
      
      def self.service_name_for_code(service_code)
        ServiceTypes[service_code] || begin
          name = service_code.downcase.split('_').collect{|word| word.capitalize }.join(' ')
          "FedEx #{name.sub(/Fedex /, '')}"
        end
      end
      
      def requirements
        [:key, :password, :account, :login]
      end
      
      def find_rates(shipment, opts = {})
        if accepts_etd?(shipment.destination)
          opts = @options.merge(opts)
          NUMBER_OF_RATE_REQUEST_TRIES.times do
            shipment.destination.address_type = unless validation_disabled?(opts)
                                         set_address_type?(shipment.destination) ? validate_address(shipment.destination, opts) : 'RESIDENTIAL'
                                       else
                                         opts[:default_address_type] || 'RESIDENTIAL'
                                       end
            break if is_domestic_business_or_international?(shipment.origin, shipment.destination, shipment.destination.address_type)
          end
          rates_response = ''
          NUMBER_OF_RATE_REQUEST_TRIES.times do
            request = build_rate_request(shipment, opts)
            self.response = response = commit(save_request(request))
            rates_response = parse_rate_response(shipment.origin, shipment.destination, shipment.packages, response, opts)
            break if is_domestic_and_contains_smart_post_or_international?(shipment.origin, shipment.destination, rates_response)
          end
          rates_response
        else 
          RateResponse.new(true, '', {}, :rates => [])
        end
      end

      def find_tracking_info(tracking_number, opts={})
        opts = @options.merge(opts)
        request = build_tracking_request(tracking_number, opts)
        response = commit(save_request(request))
        parse_tracking_response(response, opts)
      end
      
      def validate_address(address, opts={})
        opts = @options.merge(opts)
        request = build_address_validation_request(address, opts)
        response = commit(save_request(request))
        parse_validate_address_response(response, opts)
      end
      
      def create_shipping_label(shipment, options={})
        options = @options.update(options)
        request = build_process_shipment_request(shipment, options)
        response = commit(save_request(request))
        # parse_process_shipment_response(shipment, response, opts)
        # shipping_label_request = build_shipping_label_request(shipment_object, options)
        # response = commit(:GetPostageLabelXML, shipping_label_request, (options[:test] || false))
        return response
      end
      
      # def ship_package(shipper, origin, destination, packages, opts={})
      #   opts = @options.merge(opts)  
      #   shipment = Shipment.new(
      #     :shipper => shipper,
      #     :payer => (opts[:payer] || shipper),
      #     :origin => origin,
      #     :destination => destination,
      #     :packages => packages,
      #     :number => opts[:shipment_number],
      #     :value => opts[:value],
      #     :service => (opts[:service_type_code] || 'GROUND_HOME_DELIVERY')
      #   )
      #   request = build_process_shipment_request(shipment, opts)
      #   shipment.log(request)
      #   response = commit(save_request(request))
      #   shipment.log(response)
      #   parse_process_shipment_response(shipment, response, opts)
      # end
      
      def upload_image(image_id, image)
        request = build_upload_image_request(image_id, image)
        response = commit(save_request(request))
        parse_upload_image_response(response)
      end

      def close_shipment(opts={})
        if close_shipment_smart_post(opts)
          close_shipment_ground(opts)
        else; false; end
      end

      def close_shipment_smart_post(opts={})
        request = build_close_shipment_smart_post(opts)
        response = commit(save_request(request))
        parse_close_shipment_smart_post_response(response)
      end
      
      def close_shipment_ground(opts={})
        request = build_close_shipment_ground(opts)
        response = commit(save_request(request))
        parse_close_shipment_ground_response(response)
      end

      def return_package(shipper, origin, destination, packages, opts={})
        ship_package(shipper, origin, destination, packages, opts.merge(:return => true))
      end

    protected

      ### build requests
      def build_process_shipment_request(shipment, opts={})
        XmlNode.new('ProcessShipmentRequest', 'xmlns' => 'http://fedex.com/ws/ship/v10') do |root_node|
          root_node << build_request_header 
          root_node << build_version('ship', 10, 0, 0)
          root_node << build_requested_shipment_for_process_shipment(shipment, opts)
        end.to_s
      end

      def build_rate_request(shipment, opts={})
        imperial = ['US','LR','MM'].include?(shipment.origin.country_code(:alpha2))
        XmlNode.new('RateRequest', 'xmlns' => 'http://fedex.com/ws/rate/v10') do |root_node|
          root_node << build_request_header
          root_node << build_version('crs', 10, 0, 0)
          root_node << XmlNode.new('ReturnTransitAndCommit', true)
          root_node << build_requested_shipment_for_rate(shipment.origin, shipment.destination, shipment.packages, opts)
        end.to_s
      end
      
      def build_address_validation_request(address, opts={})
        XmlNode.new('AddressValidationRequest', 'xmlns' => 'http://fedex.com/ws/addressvalidation/v2') do |root_node|
          root_node << build_request_header
          root_node << build_version('aval', 2, 0, 0)
          root_node << XmlNode.new('RequestTimestamp', Time.now)
          root_node << XmlNode.new('Options') do |validation_options|
            validation_options << add_option_with_default('CheckResidentialStatus', opts[:check_resdential_status], 'true')
            validation_options << add_option_with_default('MaximumNumberOfMatches', opts[:maximim_number_of_matches], '1')
            validation_options << add_option_with_default('StreetAccuracy', opts[:street_accuracy], 'MEDIUM')
            validation_options << add_option_with_default('DirectionalAccuracy', opts[:directional_accuracy], 'MEDIUM')
            validation_options << add_option_with_default('CompanyNameAccuracy', opts[:company_name_accuracy], 'MEDIUM')
            validation_options << add_option_with_default('ConvertToUpperCase', opts[:convert_to_upper_case], 'true')
            validation_options << add_option_with_default('RecognizeAlternateCityNames', opts[:recognize_alternate_city_names], 'true')
            validation_options << add_option_with_default('ReturnParsedElements', opts[:return_parsed_elements], 'true')
          end
          root_node << XmlNode.new('AddressesToValidate') do |validation_address|
            validation_address << build_address(address, opts) 
          end         
        end.to_s
      end
      
      def build_tracking_request(tracking_number, opts={})
        XmlNode.new('TrackRequest', 'xmlns' => 'http://fedex.com/ws/track/v3') do |root_node|
          root_node << build_request_header
          
          # Version
          root_node << XmlNode.new('Version') do |version_node|
            version_node << XmlNode.new('ServiceId', 'trck')
            version_node << XmlNode.new('Major', '3')
            version_node << XmlNode.new('Intermediate', '0')
            version_node << XmlNode.new('Minor', '0')
          end
          
          root_node << XmlNode.new('PackageIdentifier') do |package_node|
            package_node << XmlNode.new('Value', tracking_number)
            package_node << XmlNode.new('Type', PackageIdentifierTypes[opts['package_identifier_type'] || 'tracking_number'])
          end
          
          root_node << XmlNode.new('ShipDateRangeBegin', opts['ship_date_range_begin']) if opts['ship_date_range_begin']
          root_node << XmlNode.new('ShipDateRangeEnd', opts['ship_date_range_end']) if opts['ship_date_range_end']
          root_node << XmlNode.new('IncludeDetailedScans', 1)
        end.to_s
      end
      
      def build_upload_image_request(image_id, image)
        XmlNode.new('UploadImagesRequest', 'xmlns' => 'http://fedex.com/ws/uploaddocument/v1') do |root_node|
          root_node << build_request_header 
          root_node << build_version('cdus', 1, 1, 0)
          root_node << XmlNode.new('Images') do |img_node|
            img_node << XmlNode.new('Id', image_id)
            img_node << XmlNode.new('Image', image)
          end
       end.to_s
      end
      
      def build_close_shipment_ground(opts={})
        XmlNode.new('GroundCloseWithDocumentsRequest', 'xmlns' => 'http://fedex.com/ws/close/v2') do |root_node|
          root_node << build_request_header
          root_node << build_version('clos', 2, 0, 0)
          root_node << XmlNode.new('CloseDate', Date.today.to_s)
          root_node << XmlNode.new('CloseDocumentSpecification') do |spec|
            spec << XmlNode.new('CloseDocumentTypes', 'MANIFEST')
          end
        end.to_s
      end

      def build_close_shipment_smart_post(opts={})
        XmlNode.new('SmartPostCloseRequest', 'xmlns' => 'http://fedex.com/ws/close/v2') do |root_node|
          root_node << build_request_header
          root_node << build_version('clos', 2, 0, 0)
          root_node << add_option_with_default('HubId', opts[:hub_id], '5531')
          root_node << XmlNode.new('DestinationCountryCode', 'US')
          root_node << XmlNode.new('PickUpCarrier', 'FXSP')
        end.to_s
      end
      
      ### build message helpers
      def build_requested_shipment_for_process_shipment(shipment, opts={})
        XmlNode.new('RequestedShipment') do |rs|
          
          service_type = opts[:service_type_code] || 'GROUND_HOME_DELIVERY'
          rs << XmlNode.new('ShipTimestamp', ship_date)
          rs << add_option_with_default('DropoffType', opts[:dropoff_type], 'REGULAR_PICKUP')
          rs << XmlNode.new('ServiceType', service_type)
          rs << add_option_with_default('PackagingType', opts[:package_type], 'YOUR_PACKAGING')

          sopts = ship_options(opts)
          rs << build_location('Shipper', shipment.shipper, sopts[:shipper])
          rs << build_location('Recipient', shipment.destination, sopts[:recipient])
          if shipment.shipper != shipment.origin
            rs << build_location('Origin', shipment.origin, opts)
          end
          
          rs << build_payment('ShippingChargesPayment', opts[:return] ? 'RECIPIENT' : 'SENDER', opts[:account], shipment.origin.country_code(:alpha2))
          rs << build_shipment_special_services_requested(shipment, opts)
          (rs << build_customs_clearence_detail(shipment, opts[:account], opts)) if has_customs_documents?(shipment, opts)        
          (rs << build_smart_post_detail(opts)) if service_type.eql?('SMART_POST')
          rs << if use_paper_labels?(shipment, opts)
                  build_shipping_label_specification(opts.merge(:image_type => 'PDF', :label_stock_type => 'PAPER_8.5X11_BOTTOM_HALF_LABEL'))
                else  
                  build_shipping_label_specification(opts)
                end
          (rs << build_shipping_document_specification(opts)) if has_customs_documents?(shipment, opts)
          rs << XmlNode.new('RateRequestTypes', 'ACCOUNT')
          
          build_packages(rs, shipment.origin, shipment.destination, shipment.packages, opts)
          
        end
      end
      
      def build_requested_shipment_for_rate(origin, destination, packages, opts={})
        XmlNode.new('RequestedShipment') do |rs|

          rs << add_option_with_default('DropoffType', opts[:dropoff_type], 'REGULAR_PICKUP')
          rs << add_option_with_default('PackagingType', opts[:packaging_type], 'YOUR_PACKAGING')

          ropts = rate_options(origin, destination, opts)
          rs << build_location('Shipper', (opts[:shipper] || origin), ropts[:shipper])
          rs << build_location('Recipient', destination, ropts[:recipient])
          if opts[:shipper] and opts[:shipper] != origin
            rs << build_location('Origin', origin)
          end

          rs << build_smart_post_detail(opts)
          rs << XmlNode.new('RateRequestTypes', 'ACCOUNT')
          build_packages(rs, origin, destination, packages, opts)

        end
      end

      def build_packages(parent, origin, destination, packages, opts)
        parent << XmlNode.new('PackageCount', packages.size)
        packages.each_with_index do |pkg, i|
          parent << XmlNode.new('RequestedPackageLineItems') do |rps|
            rps << XmlNode.new('SequenceNumber', i+1)
            rps << XmlNode.new('GroupPackageCount', i+1)
            (rps << build_insured_value(pkg)) if pkg.insured_value and has_package_services?(opts)
            rps << build_weight(origin, pkg)
            rps << build_dimensions(origin, pkg)
            add_option(rps, 'ItemDescription', opts[:item_description])
            if has_customer_references?(opts)
              rps << build_customer_references_for_package(pkg)
              (rps << build_package_special_services_requested(pkg, opts)) if has_package_services?(opts)
            end
          end
        end
      end
      
      def build_request_header
        web_authentication_detail = XmlNode.new('WebAuthenticationDetail') do |wad|
          wad << XmlNode.new('UserCredential') do |uc|
            uc << XmlNode.new('Key', @options[:key])
            uc << XmlNode.new('Password', @options[:password])
          end
        end
        client_detail = XmlNode.new('ClientDetail') do |cd|
          cd << XmlNode.new('AccountNumber', @options[:account])
          cd << XmlNode.new('MeterNumber', @options[:login])
        end
        trasaction_detail = XmlNode.new('TransactionDetail') do |td|
          td << XmlNode.new('CustomerTransactionId', 'ActiveShipping') # TODO: Need to do something better with this..
        end
        [web_authentication_detail, client_detail, trasaction_detail]
      end
            
      def build_location(location_node, location, opts={})
        XmlNode.new(location_node) do |loc_node|
          add_option(loc_node, 'AccountNumber', opts[:account])
          if opts[:tins]
            loc_node << XmlNode.new('Tins') do |tins_node|
              tins_node << XmlNode.new('TinType', 'BUSINESS_NATIONAL')
              tins_node << XmlNode.new('Number', opts[:tins])
            end
          end
          if (location.name or location.company)
            loc_node << XmlNode.new('Contact') do |contact_node|
              if location.attention_name ? location.attention_name.empty? : true
                add_attribute(contact_node, 'PersonName', location, :name)
                add_attribute(contact_node, 'CompanyName', location, :company) unless address_is_residential?(location, opts)
              else
                add_attribute(contact_node, 'PersonName', location, :attention_name)
                add_attribute(contact_node, 'CompanyName', location, :name) unless address_is_residential?(location, opts)
              end
              add_attribute(contact_node, 'PhoneNumber', location, :phone)
            end
          end
          loc_node << build_address(location, opts)
        end
      end
      
      def build_address(location, opts={})
       XmlNode.new('Address') do |address_node|
         unless opts[:only_country_and_zip]
           add_attribute(address_node, 'StreetLines', location, :address1)
           add_attribute(address_node, 'StreetLines', location, :address2)
           add_attribute(address_node, 'City', location, :city)
           add_attribute(address_node, 'StateOrProvinceCode', location, :province)
         end
         address_node << XmlNode.new('PostalCode', location.postal_code)
         address_node << XmlNode.new("CountryCode", location.country_code(:alpha2))
         if address_is_residential?(location, opts)
           address_node << XmlNode.new('Residential', 'true') 
         end
       end
       
      end
      
      def build_customs_clearence_detail(shipment, account, opts={})
        XmlNode.new('CustomsClearanceDetail') do |node|
          if has_broker?(shipment, opts)
            node << add_option_with_default('ClearanceBrokerage', opts[:clearance_brokerage], 'BROKER_SELECT')
            node << build_payment('DutiesPayment', 'RECIPIENT')
          else
            node << build_payment('DutiesPayment', 'SENDER', opts[:account], shipment.origin.country_code(:alpha2))
          end
          #node << build_total_customs_value(shipment.packages)
          value = shipment.packages.inject(0){|v,p| v += package_value(p).dollars}
          node << XmlNode.new('CustomsValue') do |cust|
            cust << XmlNode.new('Currency', shipment.packages.first.currency)
            cust << XmlNode.new('Amount', value)
          end
          
          node << XmlNode.new('PartiesToTransactionAreRelated', false)
          
          # node << build_commercial_invoice(shipment, opts) 
          shipping_cost = shipment.packages.inject(0){|v,p| v += p.cost.dollars}  
          pkg = shipment.packages.first      
          node << XmlNode.new('CommercialInvoice') do |invoice|
            invoice << build_value('FreightCharge', Money.new(shipping_cost, pkg.currency))
            invoice << XmlNode.new('DeclarationStatment', DECLARATION_STATEMENT)
            invoice << XmlNode.new('Purpose', 'SOLD')
            invoice << XmlNode.new('CustomerInvoiceNumber', pkg.reference_1)
            invoice << XmlNode.new('TermsOfSale', 'CFR_OR_CPT')
          end
          
          # build_commodities(node, shipment.origin, shipment.packages)
          shipment.packages.each do |pkg|
            customs_declaration = pkg.customs_declarations.first
            unit_count = pkg.unit_count          
            node << XmlNode.new('Commodities') do |commodities|
              commodities << XmlNode.new('NumberOfPieces', unit_count)
              commodities << XmlNode.new('Description', customs_declaration.description)
              commodities << XmlNode.new('CountryOfManufacture', 'US')
              commodities << build_weight(shipment.origin, pkg)
              commodities << XmlNode.new('Quantity', unit_count)
              commodities << XmlNode.new('QuantityUnits', 'EA')
              commodities << build_value('UnitPrice', Money.new(package_value(pkg).cents/unit_count, pkg.currency))
              commodities << build_value('CustomsValue', Money.new(package_value(pkg).cents, pkg.currency))
            end
          end
        end
      end
      
      # def build_commodities(parent, origin, packages)
      #   packages.each do |pkg|
      #     customs_declaration = pkg.customs_declarations.first
      #     unit_count = pkg.unit_count          
      #     parent << XmlNode.new('Commodities') do |node|
      #       node << XmlNode.new('NumberOfPieces', unit_count)
      #       node << XmlNode.new('Description', customs_declaration.description)
      #       node << XmlNode.new('CountryOfManufacture', 'US')
      #       node << build_weight(origin, pkg)
      #       node << XmlNode.new('Quantity', unit_count)
      #       node << XmlNode.new('QuantityUnits', 'EA')
      #       node << build_value('UnitPrice', Money.new(package_value(pkg).cents/unit_count, pkg.currency))
      #       node << build_value('CustomsValue', Money.new(package_value(pkg).cents, pkg.currency))
      #     end
      #   end
      # end
         
      # def build_commercial_invoice(shipment, opts)
      #   shipping_cost = shipment.packages.inject(0){|v,p| v += p.cost.dollars}  
      #   pkg = shipment.packages.first      
      #   XmlNode.new('CommercialInvoice') do |invoice|
      #     invoice << build_value('FreightCharge', Money.new(shipping_cost, pkg.currency))
      #     invoice << XmlNode.new('DeclarationStatment', DECLARATION_STATEMENT)
      #     invoice << XmlNode.new('Purpose', 'SOLD')
      #     invoice << XmlNode.new('CustomerInvoiceNumber', pkg.reference_1)
      #     invoice << XmlNode.new('TermsOfSale', 'CFR_OR_CPT')
      #   end
      # end
      
      
      # 
      # def build_broker(shipment, opts={})
      #   # [build_location('Broker', shipment.destination, opts),
      #   #  add_option_with_default('ClearanceBrokerage', opts[:clearance_brokerage], 'BROKER_SELECT')]
      #   add_option_with_default('ClearanceBrokerage', opts[:clearance_brokerage], 'BROKER_SELECT')
      # end
            
      def build_shipment_special_services_requested(shipment, opts)
        XmlNode.new('SpecialServicesRequested') do |serv|
          (serv << build_edt_detail(opts)) if has_customs_documents?(shipment, opts)
        end
      end

      def build_return_detail(opts={})
        [XmlNode.new('SpecialServiceTypes', 'RETURN_SHIPMENT'),
        XmlNode.new('ReturnShipmentDetail'){|edt| edt << XmlNode.new('ReturnType', 'PRINT_RETURN_LABEL')}]
      end

      def build_edt_detail(opts={})
        [XmlNode.new('SpecialServiceTypes', 'ELECTRONIC_TRADE_DOCUMENTS'),
        XmlNode.new('EtdDetail'){|edt| edt << XmlNode.new('RequestedDocumentCopies', 'COMMERCIAL_INVOICE')}]
      end
      
      def build_shipping_document_specification(opts={})
        XmlNode.new('ShippingDocumentSpecification') do |ship|
          ship << XmlNode.new('ShippingDocumentTypes', 'COMMERCIAL_INVOICE')
          ship << XmlNode.new('CommercialInvoiceDetail') do |inv|
            inv << XmlNode.new('Format') do |fmt|
              fmt << XmlNode.new('ImageType','PDF')
              fmt << XmlNode.new('StockType', 'PAPER_LETTER')
            end
            inv << XmlNode.new('CustomerImageUsages') do |usage| 
              usage << XmlNode.new('Type', 'LETTER_HEAD')
              usage << XmlNode.new('Id', 'IMAGE_1')
            end
            inv << XmlNode.new('CustomerImageUsages') do |usage| 
              usage << XmlNode.new('Type', 'SIGNATURE')
              usage << XmlNode.new('Id', 'IMAGE_2')
            end
          end
        end
      end
            
      def build_version(service_id, major, intermediate, minor)
        XmlNode.new('Version') do |node|
          node << XmlNode.new('ServiceId', service_id)
          node << XmlNode.new('Major', major)
          node << XmlNode.new('Intermediate', intermediate)
          node << XmlNode.new('Minor', minor)
        end
      end

      def build_shipping_label_specification(opts)
        XmlNode.new('LabelSpecification') do |node|
          node << add_option_with_default('LabelFormatType', opts[:label_format_type], 'COMMON2D')
          node << add_option_with_default('ImageType', opts[:image_type], 'EPL2')
          node << add_option_with_default('LabelStockType', opts[:label_stock_type], 'STOCK_4X6')
        end
      end
      
      def build_smart_post_detail(opts)
        XmlNode.new('SmartPostDetail') do |node|
          node << add_option_with_default('Indicia', opts[:indicia], 'PARCEL_SELECT')
          add_option(node, 'AncillaryEndorsement', opts[:ancillary_endorsement])
          node << add_option_with_default('HubId', opts[:hub_id], '5254')
          add_option(node, 'CustomerManifestID', opts[:customer_manifest_id])
        end
      end
      
      def build_total_insured_value(packages)
        XmlNode.new('TotalInsuredValue') do |insured_value|
          insured_value << XmlNode.new("Currency", packages.first.insured_value.currency.to_s)
          insured_value << XmlNode.new("Amount", packages.sum{|pkg| pkg.insured_value.dollars})
        end
      end

      def build_insured_value(package)
        XmlNode.new('InsuredValue') do |insured_value|
          insured_value << XmlNode.new("Currency", package.insured_value.currency.to_s)
          insured_value << XmlNode.new("Amount", package.insured_value.dollars)
        end
      end

      def build_package_special_services_requested(pkg, opts={})
        XmlNode.new('SpecialServicesRequested') do |serv|
          serv << XmlNode.new("SignatureOptionDetail") do |sig|
            sig_value = opts[:signature_option] || 500
            sig << XmlNode.new("OptionType", no_signature_required?(pkg, opts) ? 'NO_SIGNATURE_REQUIRED' : 'INDIRECT')
          end
        end
      end

      def build_pickup_detail(opts={})
        XmlNode.new('PickupDetail') do |node|
          node << XmlNode.new('ReadyDateTime', ship_date(1))
          node << XmlNode.new('LatestPickupDateTime', ship_date(1))
        end
      end
      
      def build_customer_references_for_package(pkg)
        [
         {:type => "INVOICE_NUMBER",     :val => pkg.reference_1},
         {:type => "CUSTOMER_REFERENCE", :val => pkg.reference_2}
        ].map{|ref| build_customer_reference(ref[:type], ref[:val])}
      end

      def build_customer_reference(type, val)
        XmlNode.new('CustomerReferences') do |ref_node|
          ref_node << XmlNode.new("CustomerReferenceType", type) 
          ref_node << XmlNode.new("Value", val) 
        end
      end
      
      def build_payment(payment_node, payment, account = nil, country= nil)
        XmlNode.new(payment_node) do |charges_node|
          charges_node << XmlNode.new('PaymentType', payment)
          if account
            charges_node << XmlNode.new('Payor') do |payor_node|
              payor_node << XmlNode.new('AccountNumber', account)
              payor_node << XmlNode.new('CountryCode', country)
            end
          end
        end
      end
      
      def build_weight(origin, package)
        XmlNode.new('Weight') do |tw|
          tw << XmlNode.new('Units', imperial_units?(origin) ? 'LB' : 'KG')
          tw << XmlNode.new('Value', set_weight(origin, package))
        end
      end
      
      def build_dimensions(origin, package)
        XmlNode.new('Dimensions') do |dimensions|
          [:length,:width,:height].each do |axis|
            value = ((imperial_units?(origin) ? package.inches(axis) : package.cm(axis)).to_f*1000).round/1000.0 # 3 decimals
            dimensions << XmlNode.new(axis.to_s.capitalize, value.ceil)
          end
          dimensions << XmlNode.new('Units', imperial_units?(origin) ? 'IN' : 'CM')
        end
      end
            
      def build_total_customs_value(packages)
        value = packages.inject(0){|v,p| v += package_value(p).dollars}
        XmlNode.new('CustomsValue') do |cust|
          cust << XmlNode.new('Currency', packages.first.currency)
          cust << XmlNode.new('Amount', value)
        end
      end

      def build_value(value_node, value)
        XmlNode.new(value_node) do |cust|
          cust << XmlNode.new('Currency', value.currency.iso_code)
          cust << XmlNode.new('Amount', value.dollars)
        end
      end
                                  
      #### parse responses
      def parse_rate_response(origin, destination, packages, response, opts={})
        rate_estimates = []
        success, message = nil        
        xml = get_xml_document(response)
        root_node = xml.elements['RateReply']
        success = response_success?(xml)
        message = response_message(xml)
        if success
          root_node.elements.each('RateReplyDetails') do |rated_shipment|
            service_code = rated_shipment.get_text('ServiceType').to_s
            is_saturday_delivery = rated_shipment.get_text('AppliedOptions').to_s == 'SATURDAY_DELIVERY'
            service_type = is_saturday_delivery ? "#{service_code}_SATURDAY_DELIVERY" : service_code
            currency = handle_uk_currency(rated_shipment.get_text('RatedShipmentDetails/ShipmentRateDetail/TotalNetCharge/Currency').to_s)
            transit_time = TransitTimes[rated_shipment.get_text('CommitDetails/TransitTime').to_s] || TransitTimes[MaxTransitTimes[service_code]]
            rate_estimates << RateEstimate.new(origin, destination, @@name,
                                self.class.service_name_for_code(service_type),
                                :service_code => service_code,
                                :total_price => rated_shipment.get_text('RatedShipmentDetails/ShipmentRateDetail/TotalNetCharge/Amount').to_s.to_f,
                                :currency => currency,
                                :packages => packages,
                                :delivery_range => [transit_time.days.from_now, transit_time.days.from_now],
                                :delivery_date => rated_shipment.get_text('DeliveryTimestamp').to_s)
          end
        else
          raise ActiveMerchant::Shipping::ResponseError, response
        end
        if rate_estimates.empty?
          success = false
          message = "No shipping rates could be found for the destination address" if message.blank?
        end
        RateResponse.new(success, message, Hash.from_xml(response), :rates => rate_estimates, :xml => response, :request => last_request, :log_xml => opts[:log_xml])
      end

      def parse_process_shipment_response(shipment, response, opts={})
        xml = get_xml_document(response)
        success = response_success?(xml)
        message = response_message(xml)         
        if success
          detail = xml.elements['ProcessShipmentReply/CompletedShipmentDetail']
          shipment.tracking = detail.elements['CompletedPackageDetails/TrackingIds/TrackingNumber'].text
          if net_charge = detail.elements['ShipmentRating/ShipmentRateDetails/TotalNetCharge']
            shipment.price = parse_money(net_charge)
          end
          image = detail.elements['CompletedPackageDetails/Label/Parts/Image'].text
          shipment.labels = [Label.new(:image => Base64.decode64(image), :tracking => shipment.tracking)]
          if has_customs_documents?(shipment, opts)
            invoice =  detail.elements['ShipmentDocuments/Parts/Image'].text
            shipment.labels << Label.new(:image => Base64.decode64(invoice), :tracking => shipment.tracking)
          end
        else
          shipment.errors = response_message(xml)
          raise ActiveMerchant::Shipping::ResponseError, response
        end
        shipment         
      end
      
      def parse_validate_address_response(response, opts)
        xml = get_xml_document(response)
        success = response_success?(xml)
        message = response_message(xml)
        if success
          address_type = xml.elements['AddressValidationReply/AddressResults/ProposedAddressDetails/ResidentialStatus'].text
          address_type.eql?('BUSINESS') ? 'COMMERCIAL' : (address_type.eql?('UNDETERMINED') ? 'RESIDENTIAL' : address_type)
        else
          raise ActiveMerchant::Shipping::ResponseError, response
        end
      end

      def parse_upload_image_response(response)
        xml = get_xml_document(response)
        success = response_success?(xml)
        message = response_message(xml)
        if success
          xml.elements['UploadImagesReply/ImageStatuses/Id'].text
        else
          raise ActiveMerchant::Shipping::ResponseError, response
        end
      end
      
      def parse_close_shipment_smart_post_response(response)
        xml = get_xml_document(response)
        success = response_success?(xml)
        message = response_message(xml)
        success ? true : raise(ActiveMerchant::Shipping::ResponseError, response)
      end

      def parse_close_shipment_ground_response(response)
        xml = get_xml_document(response)
        success = response_success?(xml)
        message = response_message(xml)
        if success
          images = []
          root_node = xml.elements['GroundCloseDocumentsReply/CloseDocuments']
          root_node.elements.each('Parts/Image') {|image| images << image.text}
          {:shippng_cycle => xml.elements['GroundCloseDocumentsReply/CloseDocuments/ShippingCycle'].text, :image => Base64.decode64(images.join)}
        else
          raise ActiveMerchant::Shipping::ResponseError, response
        end
      end
      
      def parse_tracking_response(response, opts)
        xml = get_xml_document(response)
        root_node = xml.elements['TrackReply']
        
        success = response_success?(xml)
        message = response_message(xml)
        
        if success
          tracking_number, origin, destination = nil
          shipment_events = []
          
          tracking_details = root_node.elements['TrackDetails']
          tracking_number = tracking_details.get_text('TrackingNumber').to_s
          
          destination_node = tracking_details.elements['DestinationAddress']
          destination = Location.new(
                :country =>     destination_node.get_text('CountryCode').to_s,
                :province =>    destination_node.get_text('StateOrProvinceCode').to_s,
                :city =>        destination_node.get_text('City').to_s
              )
          
          tracking_details.elements.each('Events') do |event|
            address  = event.elements['Address']

            city     = address.get_text('City').to_s
            state    = address.get_text('StateOrProvinceCode').to_s
            zip_code = address.get_text('PostalCode').to_s
            country  = address.get_text('CountryCode').to_s
            next if country.blank?
            
            location = Location.new(:city => city, :state => state, :postal_code => zip_code, :country => country)
            description = event.get_text('EventDescription').to_s
            
            # for now, just assume UTC, even though it probably isn't
            time = Time.parse("#{event.get_text('Timestamp').to_s}")
            zoneless_time = Time.utc(time.year, time.month, time.mday, time.hour, time.min, time.sec)
            
            shipment_events << ShipmentEvent.new(description, zoneless_time, location)
          end
          shipment_events = shipment_events.sort_by(&:time)
        else
          raise ActiveMerchant::Shipping::ResponseError, response            
        end
        
        TrackingResponse.new(success, message, Hash.from_xml(response),
          :xml => response,
          :request => last_request,
          :shipment_events => shipment_events,
          :destination => destination,
          :tracking_number => tracking_number
        )
      end
            
      def response_status_node(document)
        document.elements['/*/Notifications/']
      end
      
      def response_success?(document)
        %w{SUCCESS WARNING NOTE}.include? response_status_node(document).get_text('Severity').to_s
      end
      
      def response_message(document)
        response_node = response_status_node(document)
        "#{response_status_node(document).get_text('Severity').to_s} - #{response_node.get_text('Code').to_s}: #{response_node.get_text('Message').to_s}"
      end
      
      def parse_money(element)
        value = element.elements['Amount'].text
        currency = element.elements['Currency'].text
        Money.new((BigDecimal(value) * 100).to_i, currency)
      end
      
      #### utils
      def commit(request)
        url = test_mode ? TEST_URL : LIVE_URL
        log_request(request)
        response = ssl_post(url, request.gsub("\n",'')).gsub(/<(\/)?.*?\:(.*?)>/, '<\1\2>')        
        log_response(response)
        response
      end
      
      def handle_uk_currency(currency)
        currency =~ /UKL/i ? 'GBP' : currency
      end
      
      def imperial_units?(origin)
        ['US','LR','MM'].include?(origin.country_code(:alpha2))
      end
      
      def add_attribute(parent, node_name, obj, attr_name)
        unless (attr_val = obj.send(attr_name)).blank?
          parent << XmlNode.new(node_name, attr_val)        
        end
      end

      def add_option(parent, node_name, opt)
        parent << XmlNode.new(node_name, opt) if opt        
      end

      def add_option_with_default(node_name, opt, default)
        XmlNode.new(node_name, opt || default)
      end
      
      def address_is_residential?(address, opts={})
        unless opts[:residential].nil?
          return opts[:residential]
        end
        return (address.address_type.nil? || (opts[:service_type_code].eql?('GROUND_HOME_DELIVERY') && 
          !address.address_type.downcase.eql?('commercial')) || 
          address.address_type.downcase.eql?('residential')) &&
          !(opts[:service_type_code].eql?('FEDEX_GROUND') && 
          address.country_code(:alpha2).eql?('US'))
      end
      
      def has_package_services?(opts)
        %w(GROUND_HOME_DELIVERY STANDARD_OVERNIGHT FEDEX_2_DAY FEDEX_GROUND INTERNATIONAL_ECONOMY FEDEX_EXPRESS_SAVER).include?(opts[:service_type_code]) 
      end

      def has_broker?(shipment, opts)
        shipment.international?
      end
      
      def has_customs_documents?(shipment, opts={})
        shipment.international?
      end
      
      def has_customer_references?(opts)
        not opts[:service_type_code].eql?('SMART_POST')
      end
      
      def no_signature_required?(pkg, opts)
        sig_value = opts[:signature_option] || 500
        pkg.value.nil? or Money.new(pkg.value).dollars < sig_value or (Money.new(pkg.value).dollars > sig_value and opts[:return])
      end
      
      def use_paper_labels?(shipment, opts={})
        opts[:service_type_code].eql?('INTERNATIONAL_ECONOMY') or opts[:return]
      end
      
      def package_value(pkg)
        val = Money.new(pkg.value).cents
        Money.new(pkg.insured_value.cents < val ? val : pkg.insured_value.cents)       
      end
      
      def set_address_type?(destination)
        destination.country_code(:alpha2).eql?('US')
      end

      def set_weight(origin, package)
        if imperial_units?(origin)
          [(package.lbs.to_f*1000).round/1000.0, 1.0].max
        else
          [(package.kgs.to_f*1000).round/1000.0, 0.454].max
        end
      end      
      
      def log_request(msg)
        File.open('/tmp/fedex-request.xml', 'wb'){|f| f << (msg + "\n\n")}
      end

      def log_response(msg)
        File.open('/tmp/fedex-response.xml', 'wb'){|f| f << (msg + "\n\n")}
      end
      
      def international?(origin, destination)
        origin.country.to_s != destination.country.to_s
      end
      
      def accepts_etd?(destination)
        ETD_COUNTRIES.include?(destination.country_code(:alpha2))
      end
      
      def is_domestic_and_contains_smart_post_or_international?(origin, destination, rate_responce)
        (destination.country_code(:alpha2).eql?('US') and rate_responce.rates.any?{|r| r.service_code.eql?('SMART_POST')}) or international?(origin, destination)
      end

      def is_domestic_business_or_international?(origin, destination, validation_response)
        (destination.country_code(:alpha2).eql?('US') and validation_response.eql?('BUSINESS')) or international?(origin, destination)
      end
      
      def validation_disabled?(opts)
        opts[:test]
      end
      
      def get_xml_document(msg)
        begin
          REXML::Document.new(msg)
        rescue
          raise ActiveMerchant::Shipping::ResponseError, msg
        end
      end
      
      def ship_options(opts)
        if opts[:return]
          {:shipper => {:service => opts[:service_type_code]}, :recipient => opts}
        else
          {:recipient => {:service => opts[:service_type_code]}, :shipper => opts}
        end
      end

      def rate_options(origin, destination, opts)
        sopts = international?(origin, destination) ? {:only_country_and_zip => true, :service => opts[:service_type_code]} :  {:service => opts[:service_type_code]}
        if opts[:return]
          {:shipper => sopts, :recipient => opts}
        else
          {:recipient => sopts, :shipper =>  opts}
        end
      end
      
      def ship_date(ahead_days = 0)
        now = Time.now
        advance_days = case now.wday
                       when 0; 1
                       when 6; 2
                       else 0
                       end + ahead_days
        now.beginning_of_day.advance(:days => advance_days, :hours => 10)
      end
      
    end
  end
end