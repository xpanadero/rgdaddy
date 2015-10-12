require "rgdaddy/version"
require "net/https"
require "uri"
require 'nokogiri'

module RGDaddy

  class RGDaddyException < RuntimeError
  end

  class RGDaddy


    @@gd_sso_login_url = "https://sso.godaddy.com/v1/"
    @@gd_dns_url = "https://dns.godaddy.com"
    @@gd_zonefile_url = 'https://dns.godaddy.com/ZoneFile.aspx?zoneType=0&sa=&zone='
    @@gd_zonefile_edit_record_url = 'https://dns.godaddy.com/ZoneFile_WS.asmx/EditRecordField'
    @@gd_zonefile_save_record_url = 'https://dns.godaddy.com/ZoneFile_WS.asmx/SaveRecords'
    @@gd_zonefile_logout_url = "https://idp.godaddy.com/logout.aspx?spkey=authapigd1&from_idp=1&path=%2f&app=&realm=idp"

    @@logged_in = false
    @@auth_cookies = "";
    @@gd_nonce = "";


    def login(user = nil, password = nil)

      uri = URI.parse(@@gd_sso_login_url)
      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true
      request = Net::HTTP::Post.new(uri.request_uri,default_headers)

      request.set_form_data(
        'app' => 'fos',
        'realm' => 'idp',
        'name' => user,
        'password' => password
      )

      response = https.request(request)
      cookies_string=response.get_fields('set-cookie').collect{ |x| x.split(';')[0] }.join('; ')

      @@auth_cookies =cookies_string

      raise RGDaddyException, "Invalid authentication credentials" if !cookies_string.match(/auth\_idp/)

      @@logged_in = true

      # Follow 302 redirect and collect all the authentication cookies
      while response.code == "302"

          login=URI.parse(response.header['location'])

          https = Net::HTTP.new(login.host, login.port)
          https.use_ssl = true

          request = Net::HTTP::Get.new(login.request_uri,default_headers)
          response = https.request(request)

          cookies_string=response.get_fields('set-cookie').collect{ |x| x.split(';')[0] }.join('; ')

          @@auth_cookies << "; " << cookies_string

      end
      return true
    end

    def logout

      raise RGDaddyException, "Not logged in, please call login method first" if !@@logged_in

      uri= URI.parse(@@gd_zonefile_logout_url)

      https = Net::HTTP.new(uri.host, uri.port)
      https.use_ssl = true

      request = Net::HTTP::Get.new(uri.request_uri,default_headers)
      response = https.request(request)

      @@auth_cookies = "";
      @@logged_in = false;

    end


    def get_dns_records(zone, type ="A")

      raise RGDaddyException, "Not logged in, please call login method first" if !@@logged_in
      raise RGDaddyException, "Only A record type is currently supported" if type != "A"

      finish = false
      uri= URI.parse(@@gd_zonefile_url + zone)
      while not finish

          https = Net::HTTP.new(uri.host, uri.port)
          https.use_ssl = true

          request = Net::HTTP::Get.new(uri.request_uri,default_headers)
          response = https.request(request)

          if response.get_fields('set-cookie') != nil
              cookies_string=response.get_fields('set-cookie').collect{ |x| x.split(';')[0] }.join('; ')
              @@auth_cookies << "; " << cookies_string
          end

          if response.code == "302"
            uri=URI.parse(response.header['location'])
            if uri.host == nil
                uri=URI.parse(@@gd_dns_url + response.header['location'])
            end
          else
             finish = true
          end
      end
      parse_nonce(response.body)
      parse_dns_zone(response.body,zone)

    end


    def update_dns_record(zone,id,name,ip,ttl,type = "A")

      raise RGDaddyException, "Not logged in, please call login method first" if !@@logged_in
      raise RGDaddyException, "Only A record type is currently supported" if type != "A"

        uri = URI.parse(@@gd_zonefile_edit_record_url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri,default_headers("json"))

        request.body =
            "{\"sInput\":\"<PARAMS>\
            <PARAM name=\\\"type\\\" value=\\\"arecord\\\" />\
            <PARAM name=\\\"fieldName\\\" value=\\\"data\\\" />\
            <PARAM name=\\\"fieldValue\\\" value=\\\"#{ip}\\\" />\
            <PARAM name=\\\"lstIndex\\\" value=\\\"#{id}\\\" />\
            </PARAMS>\"}"

        response = https.request(request)

        raise RGDaddyException, "Error on EditRecord call, maybe GoDaddy has made changes on the JSON request" if !response.body.match(/SUCCESS/)

        uri = URI.parse(@@gd_zonefile_save_record_url)
        https = Net::HTTP.new(uri.host, uri.port)
        https.use_ssl = true
        request = Net::HTTP::Post.new(uri.request_uri,default_headers("json"))

        request.body =
            "{\"sInput\":\"<PARAMS>\
            <PARAM name=\\\"domainName\\\" value=\\\"#{zone}\\\" />\
            <PARAM name=\\\"zoneType\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"aRecEditCount\\\" value=\\\"1\\\" />\
            <PARAM name=\\\"aRecDeleteCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"aRecEdit0Index\\\" value=\\\"#{id}\\\" />\
            <PARAM name=\\\"cnameRecEditCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"cnameRecDeleteCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"mxRecEditCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"mxRecDeleteCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"txtRecEditCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"txtRecDeleteCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"srvRecEditCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"srvRecDeleteCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"aaaaRecEditCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"aaaaRecDeleteCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"soaRecEditCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"soaRecDeleteCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"nsRecEditCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"nsRecDeleteCount\\\" value=\\\"0\\\" />\
            <PARAM name=\\\"nonce\\\" value=\\\"#{@@gd_nonce}\\\" />\
            </PARAMS>\"}"

        response = https.request(request)

        raise RGDaddyException, "Error on SaveRecord call, maybe GoDaddy has made changes on the JSON request" if !response.body.match(/SUCCESS/)

    end

    private
      def default_headers(type = "w")

        headers = {
              'User-Agent' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2228.0 Safari/537.36',
              'Cookie' => @@auth_cookies,
              'Referer' => @@gd_zonefile_url
        }
        if type == "json"
            headers.merge!({
              "Content-Type" => "application/json",
              "Accept" => "application/json",
            })
        end
        return headers

      end

      def parse_dns_zone(html_zone,zone, type = "A")
          #page = Nokogiri::HTML(open("outgd.html"), nil, 'utf-8');
          page = Nokogiri::HTML(html_zone)

          records_array = []

          page.xpath("//table[contains(@id,'tblARecords')]/tr").map do |item|
            name = item.at_xpath(".//input[contains(@id,'txtHost')]")
            if name
                record = Record.new()
                record.zone = zone
                record.id = name['id'].match(/tblARecords\_(\d+)\_txtHost/)[1].to_i
                record.name = name['value']
                record.ip = item.at_xpath(".//input[contains(@id,'txtPointsto')]")['value']
                record.ttl = item.at_xpath(".//input[contains(@id,'TTL')]")['value']
                records_array.push(record)
            end
          end
          return records_array
      end

      def parse_nonce(html_zone)
          @@gd_nonce=html_zone.match(/nonce\=\"(\w+)\"\;/)[1]
          raise RGDaddyException, "Error parsing GoDaddy  nonce, maybe a change has made on the API" if @@gd_nonce  == nil
      end

  end

  class Record
    attr_accessor :zone,:id,:name,:ip,:ttl

    def initalize()
        set(nil,-1,nil,nil,-1)
    end

    def set(zone,id,name,ip,ttl)
      # Instance variables
      @zone = zone;
      @id = id;
      @name = name;
      @ip = ip;
      @ttl = ttl;
    end

    def to_s
      "Zone: #{@zone} - ID: #{@id} - Name: #{@name} - IP: #{@ip} - TTL: #{@ttl} seconds"
    end

  end

end

