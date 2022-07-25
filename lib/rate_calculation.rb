require "rate_calculation/version"
module RateCalculation
  class GetRate

    require "json"

    def initialize(origin_port,destination_port)
      if origin_port && destination_port
        file = File.read(File.join(__dir__, 'response.json'))
        @response = JSON.parse(file)
        @origin_port = origin_port
        @destination_port = destination_port
      elsif !origin_port
        raise "Origin Port is missing"
      elsif !destination_port
        raise "Detination Port is missing"
      end
    end
    
    def cheapest_direct_sailing
      @matched_sailings = @response["sailings"].select {|key, hash| key["origin_port"].eql?(@origin_port) && key["destination_port"].eql?(@destination_port)}
      rate_calculation("direct")
    end
    
    def cheapest_direct_or_indirect_sailing
      @matched_sailings = @response["sailings"].select {|key, hash| key["origin_port"].eql?(@origin_port) || key["destination_port"].eql?(@destination_port)}
      rate_calculation("direct_or_indirect")
    end
    
    def fastest_sailing_legs
      rate_arr = []
      @matched_sailings = @response["sailings"].select {|key, hash| key["origin_port"].eql?(@origin_port) || key["destination_port"].eql?(@destination_port)}
      unless @matched_sailings.blank?
        @matched_sailings.each do |sailing|
          indirect_sailings = @matched_sailings - @matched_sailings.select {|key, hash| key["origin_port"].eql?(@origin_port) && key["destination_port"].eql?(@destination_port)}
          unless indirect_sailings.blank?
            sailing_ending_with_destination_ports = indirect_sailings - indirect_sailings.select {|key, hash| key["origin_port"].eql?(@origin_port) }
            sailing_beginning_with_origin_ports =  indirect_sailings - indirect_sailings.select {|key, hash| key["destination_port"].eql?(@destination_port)}
            if sailing_beginning_with_origin_ports.present? && sailing_ending_with_destination_ports.present?
              @matched_sailings = @matched_sailings - indirect_sailings
              sailing_beginning_with_origin_ports.each do |sailing_beginning_with_origin_port|
                sailing_beginning_with_origin_port_days = (sailing_beginning_with_origin_port["arrival_date"].to_date - sailing_beginning_with_origin_port["departure_date"].to_date).to_i
                sailing_ending_with_destination_ports.each do |sailing_ending_with_destination_port|
                  sailing_ending_with_destination_port_days = (sailing_ending_with_destination_port["arrival_date"].to_date - sailing_ending_with_destination_port["departure_date"].to_date).to_i
                  org_port =  sailing_beginning_with_origin_port["origin_port"]+","+sailing_ending_with_destination_port["origin_port"]
                  sailing_code = sailing_beginning_with_origin_port["sailing_code"]+","+sailing_ending_with_destination_port["sailing_code"]
                  dest_port = sailing_beginning_with_origin_port["destination_port"]+","+sailing_ending_with_destination_port["destination_port"]
                  departure_date = sailing_beginning_with_origin_port["departure_date"]+","+sailing_ending_with_destination_port["departure_date"]
                  arrival_date = sailing_beginning_with_origin_port["arrival_date"]+","+sailing_ending_with_destination_port["arrival_date"]
                  rate_arr << {"origin_port"=>org_port, "destination_port"=>dest_port, "departure_date"=>departure_date, "arrival_date"=>arrival_date, "sailing_code"=>sailing_code, "date_diff" => (sailing_ending_with_destination_port_days + sailing_beginning_with_origin_port_days) }.merge!("rate" => sailing_beginning_with_origin_port["rate"].to_f+sailing_ending_with_destination_port["rate"].to_f , "rate_currency" => "EUR" )
                end
              end
            end  
          end
        end  
        @matched_sailings.each do |sailing|
          rate_arr << sailing.merge!({"date_diff" => (sailing["arrival_date"].to_date - sailing["departure_date"].to_date).to_i})
        end
      end  
      unless rate_arr.blank?
        fastest_direct_or_indirect_sailing_leg = rate_arr.sort_by { |k| k["date_diff"].to_f}.first 
        fastest_direct_or_indirect_sailing_leg_arr = []
        if fastest_direct_or_indirect_sailing_leg["sailing_code"].split(",").length >  1
          fastest_direct_or_indirect_sailing_leg["sailing_code"].split(",").each do |sailing_code|
            fastest_direct_or_indirect_sailing_leg_arr << @response["sailings"].select {|key,hash| key["sailing_code"].eql?(sailing_code)}.first.merge!(@response["rates"].select {|key,hash| key["sailing_code"].eql?(sailing_code)}.first).to_json   
          end
          fastest_direct_or_indirect_sailing_leg_arr
        else
          fastest_direct_or_indirect_sailing_leg_arr << @response["sailings"].select {|key,hash| key["sailing_code"].eql?(fastest_direct_or_indirect_sailing_leg["sailing_code"])}.first.merge!(@response["rates"].select {|key,hash| key["sailing_code"].eql?(fastest_direct_or_indirect_sailing_leg["sailing_code"])}.first).to_json
        end 
      else
        rate_arr << {:error => "Sailing not found for origin and destination combination", :timestamp => Time.now}.to_json
      end    
        
    end
    
    private
    
      def rate_calculation(sailing_type)
        rate_arr = []
        unless @matched_sailings.blank?
          @matched_sailings.each do |sailing|
            @response["rates"].each do |rate|
              if rate["sailing_code"].eql?(sailing["sailing_code"])
                exchange_rate_reparture_date = @response["exchange_rates"][sailing["departure_date"]]
                if exchange_rate_reparture_date.present?
                  #convert rates to european currency
                  if ["USD","JPY"].include?(rate["rate_currency"])
                    rate_arr << sailing.merge!({ "rate" => (rate["rate"].to_f/exchange_rate_reparture_date[rate["rate_currency"].downcase]).round(2).to_s, "rate_currency" => "EUR"})
                  else
                    rate_arr << sailing.merge!(rate)
                  end
                end    
              end  
            end 
          end
          unless rate_arr.blank?
            cheapest_direct_sailing_arr = []
            if sailing_type.eql?("direct")
              cheapest_direct_sailing = rate_arr.sort_by { |k| k["rate"].to_f}.first #cheapest direct sailing in Euro
              cheapest_direct_sailing_arr << cheap_direct_sailing(cheapest_direct_sailing)#chapest direct sailing from with original rate_currency
            elsif sailing_type.eql?("direct_or_indirect")  
              indirect_sailings = rate_arr - rate_arr.select {|key, hash| key["origin_port"].eql?(@origin_port) && key["destination_port"].eql?(@destination_port)}
              unless indirect_sailings.blank? 
                sailing_ending_with_destination_ports = indirect_sailings - indirect_sailings.select {|key, hash| key["origin_port"].eql?(@origin_port) }
                sailing_beginning_with_origin_ports =  indirect_sailings - indirect_sailings.select {|key, hash| key["destination_port"].eql?(@destination_port)}
                if sailing_beginning_with_origin_ports.present? && sailing_ending_with_destination_ports.present?
                  rate_arr = rate_arr - indirect_sailings
                  sailing_beginning_with_origin_ports.each do |sailing_beginning_with_origin_port|
                    sailing_ending_with_destination_ports.each do |sailing_ending_with_destination_port|
                      org_port =  sailing_beginning_with_origin_port["origin_port"]+","+sailing_ending_with_destination_port["origin_port"]
                      sailing_code = sailing_beginning_with_origin_port["sailing_code"]+","+sailing_ending_with_destination_port["sailing_code"]
                      dest_port = sailing_beginning_with_origin_port["destination_port"]+","+sailing_ending_with_destination_port["destination_port"]
                      departure_date = sailing_beginning_with_origin_port["departure_date"]+","+sailing_ending_with_destination_port["departure_date"]
                      arrival_date = sailing_beginning_with_origin_port["arrival_date"]+","+sailing_ending_with_destination_port["arrival_date"]
                      rate_arr << {"origin_port"=>org_port, "destination_port"=>dest_port, "departure_date"=>departure_date, "arrival_date"=>arrival_date, "sailing_code"=>sailing_code}.merge!("rate" => sailing_beginning_with_origin_port["rate"].to_f+sailing_ending_with_destination_port["rate"].to_f , "rate_currency" => "EUR" )
                    end  
                  end                    
                end  
              end
              cheapest_direct_or_indirect_sailing = rate_arr.sort_by { |k| k["rate"].to_f}.first #cheapest direct or indirect sailing in Euro
              cheapest_direct_or_indirect_sailing_arr = []
              if cheapest_direct_or_indirect_sailing["sailing_code"].split(",").length >  1
                cheapest_direct_or_indirect_sailing["sailing_code"].split(",").each do |sailing_code|
                  cheapest_direct_or_indirect_sailing_arr << @response["sailings"].select {|key,hash| key["sailing_code"].eql?(sailing_code)}.first.merge!(@response["rates"].select {|key,hash| key["sailing_code"].eql?(sailing_code)}.first).to_json   
                end
                cheapest_direct_or_indirect_sailing_arr
              else
                cheapest_direct_or_indirect_sailing_arr << cheap_direct_sailing(cheapest_direct_or_indirect_sailing)
              end    
            end   
          else
            rate_arr << {:error => "Sailing not found for origin and destination combination", :timestamp => Time.now}.to_json
          end    
        else
          rate_arr << {:error => "Sailing not found for origin and destination combination", :timestamp => Time.now}.to_json
        end    
      end
      
      def cheap_direct_sailing(cheapest_direct_sailing)
        @response["sailings"].select {|key,hash| key["sailing_code"].eql?(cheapest_direct_sailing["sailing_code"])}.first.merge!(@response["rates"].select {|key,hash| key["sailing_code"].eql?(cheapest_direct_sailing["sailing_code"])}.first).to_json   
      end 
  end
end
