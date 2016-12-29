module MarkdownFormatter
	class << self

    def notam(all_notams)
      ret = "\n\n"
      all_notams.each_pair do |icao_code, notams_for_aerodrome|
        ret << "=============================\n\n"
        ret << "*NOTAMs for #{icao_code}*\n\n"
        notams_for_aerodrome.each do |notam|
          ret << "--------------------------\n\n"
          ret << "#{notam[:signature]}\n" if notam[:signature]
          ret << "\nCreated at #{notam[:created_at].strftime("%F %H:%M")} by #{notam[:source]}\n" if notam[:created_at]
          ret << "_Valid from #{notam[:valid_from].strftime("%F %H:%M (%A)")} to #{notam[:valid_to].strftime("%F %H:%M (%A)")}_\n" if notam[:valid_from]
          ret << "\n*#{notam[:message]}*\n\n"
        end
        ret << "\n"
      end
      ret
    end

    def weather(data)
      ret = "\n\n"
      data.each_pair do |icao_code, data_for_aerodrome|
        ret << "\n=== *#{icao_code}* ===\n"
        ret << data_for_aerodrome[:data]
        ret << "\n"
      end
      ret
    end

  end
end
