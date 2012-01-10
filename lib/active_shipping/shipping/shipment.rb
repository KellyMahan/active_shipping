module ActiveMerchant #:nodoc:
  module Shipping
    
    #TODO This really needs some work before integrating into active shipping.
    
    
    class Shipment
      require 'nokogiri'
      class RequiredOptionError < StandardError; end
      class SaveLabelError < StandardError; end
      class VerifyRatesError < StandardError; end
      #required attributes
      attr_accessor :ship_to, :shipper, :carrier, :options, :rate_xml, :label_xml, :tracking, :postage, :error
      #attr_accessor :service_type_code #available options in ActiveShipping::Shipping::Ups::DEFAULT_SERVICES
      
      
      
      # optional attributes
      #attr_accessor :ship_from #required if pickup location is different from shipper
      #attr_accessor :description #only required for international shipments
      #attr_accessor :return_service_code
      PAYMENT_TYPES = [:credit_card, :bill_to_account]
      REQUIRED_SHIPMENT_OPTIONS = [:service_type_code, :payment_type, :packages, :reference_number, :print_method_code]
      SHIPMENT_OPTIONS = [
          :ship_from, 
          :description, 
          :return_service_code, 
          :documents_only, 
          :service_type_description,
          :credit_card,
          :credit_card_billing_location,
          :label_date,
          :po_zip_code,
          :address_service_requested,
          :sunday_holiday_delivery,
          :value,
          :signed_by,
          :quantity,
          :order_id,
          :delivery_instructions,
          :line_items,
          :residential
        ]
        
      # UPS_DEFAULT_OPTIONS= {
      #   :service_type_code => "03", 
      #   :payment_type=> :bill_to_account, 
      #   :description=>"",
      #   :print_method_code => "ZPL"
      # }
      
      
      def initialize(shipper, ship_to, carrier, options={})
        @options = options
        @carrier = carrier.new(options)
        @shipper = Location.from(shipper)
        @ship_to = Location.from(ship_to)
        set_options(options)
        @ship_from = Location.from(@ship_from) if @ship_from
      end
      
      def test=(value)
        @options[:test] = value
      end
      
      def check_for_customs
         (self.ship_to.province == "AE" || self.ship_to.province == "AP" || self.ship_to.province == "AA")
      end
      
      def international?
        self.ship_to.country != self.shipper.country
      end

      def request_label(shipmentdigest = nil)
        case @carrier
        when ActiveMerchant::Shipping::USPS
          @label_xml = @carrier.find_shipping_label_certify(self, @options)
          return @label_xml
        when ActiveMerchant::Shipping::Endicia
          @label_xml = @carrier.create_shipping_label(self, @options)
          doc = Hpricot(@label_xml)
          @tracking = (doc/'trackingnumber')._?.inner_text
          @postage = (doc/'finalpostage')._?.inner_text.to_f
          @error = "#{(doc/"errormessage")._?.inner_text.gsub(/"|\n|\r/,'')}" unless (doc/"errormessage")._?.inner_text.empty?
          return @label_xml
        when ActiveMerchant::Shipping::FedEx
          @label_xml = @carrier.create_shipping_label(self, @options)
          doc = Hpricot(@label_xml)
          @tracking = (doc/'tracking/trackingnumber')._?.inner_text
          @postage = (doc/'estimatedcharges/discountedcharges/shipmentnetcharge')._?.inner_text.to_f
          @error = "#{(doc/"error/message")._?.inner_text.gsub(/"|\n|\r/,'')}" unless (doc/"error/message")._?.inner_text.empty?
          return @label_xml
        else
          @label_xml, success, message = @carrier.find_shipping_accept(shipment_digest, @options)
          if success
            return @label_xml
          else
            return "<error>#{message}</error>"
          end
        end
      end
      
      
      def request_pickup(tracking_number)
        case @carrier
        when ActiveMerchant::Shipping::Endicia
          return @carrier.request_pickup(self, @options.merge(:tracking_number=>tracking_number))
        else
          return "<error>Only Endicia is supported right now.</error>"
        end
      end
      
      
      def error_data
        doc = Hpricot(@label_xml)
        case @carrier
        when ActiveMerchant::Shipping::FedEx
          response = (doc/'error'/'message').inner_text.gsub(/(\n|\t|\s)/,"") rescue nil
        when ActiveMerchant::Shipping::Endicia
          response = (doc/"errormessage").inner_text.gsub(/(\n|\t|\s)/,"") rescue nil
        else
          raise SaveLabelError, "Error data for #{@carrier} not supported."
        end
        if response=="" || response.nil?
          return nil
        else
          return response
        end 
      end
      
      def label_data
        doc = Hpricot(@label_xml)
        case @carrier
        when ActiveMerchant::Shipping::USPS
          return (doc/"deliveryconfirmationlabel").inner_text.gsub(/(\n|\t|\s)/,"") rescue nil
        when ActiveMerchant::Shipping::FedEx
          return (doc/"labels/outboundlabel").inner_text.gsub(/(\n|\t|\s)/,"") rescue nil
        when ActiveMerchant::Shipping::Endicia
          return (doc/"base64labelimage").inner_text.gsub(/(\n|\t|\s)/,"") rescue nil
        when ActiveMerchant::Shipping::UPS
          return (doc/"graphicimage").inner_text.gsub(/(\n|\t|\s)/,"") rescue nil
        else
          raise SaveLabelError, "Label data for #{@carrier} not supported."
        end
      end
      
      def customs_data
        tempdata = nil
        doc = Hpricot(@label_xml)
        case @carrier
        when ActiveMerchant::Shipping::Endicia
          if self.check_for_customs
            tempdata = (doc/"customsform"/"image").first.inner_text.gsub(/(\n|\t|\s)/,"")
          end
        else
          #raise SaveLabelError, "Customs data for #{@carrier} not supported."
        end
        return tempdata
      end
      
      def save_label_to_file(path)
        if @label_xml
          begin
            label_string = label_data
            if label_string.nil? || label_string == ""
              raise SaveLabelError, "Label was not returned."
            end
            File.open(path, 'wb') do |f|
              f.write Base64.decode64(label_string)
            end
          rescue Exception => e
            raise SaveLabelError, "Error writing to file: '#{path}' \n#{e}"
          end
        else
          raise SaveLabelError, "Label has not been requested successfully."
        end
      end
              
      def shipment_digest
        if @rate_xml
          doc = Hpricot(@rate_xml)
          return case @carrier
          when ActiveMerchant::Shipping::UPS
            (doc/"shipmentdigest").inner_text
          else
            raise SaveLabelError, "Requesting label for #{@carrier} not supported."
          end
        end
      end
      
      def set_options(options)
        REQUIRED_SHIPMENT_OPTIONS.each do |option|
          if options[option]
            eval("@#{option} = options[:#{option}]") 
          else
            raise RequiredOptionError, "Required option :#{option} not supplied."
          end
        end
        SHIPMENT_OPTIONS.each do |option|
          eval("@#{option} = options[:#{option}]") if options[option]
        end
      end
      
      def self.set_attributes
        
        REQUIRED_SHIPMENT_OPTIONS.each do |option|
          eval("attr_accessor :#{option}")
        end
        SHIPMENT_OPTIONS.each do |option|
          eval("attr_accessor :#{option}")
        end
      end
            
      self.set_attributes
      
    end
    
  end
end