# frozen_string_literal: true

require "net/http"
require "http-cookie"

module RelatonUn
  # Page of hit collection.
  class HitCollection < RelatonBib::HitCollection
    AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_5) AppleWebKit/537.36 " \
            "(KHTML, like Gecko) Chrome/85.0.4183.102 Safari/537.36"
    DOMAIN = "https://documents.un.org"
    BOUNDARY = "----WebKitFormBoundaryVarT9Z7AFUzw2lma"

    # @param text [String] reference to search
    def initialize(text) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      super
      @uri = URI.parse DOMAIN
      @jar = HTTP::CookieJar.new
      @http = Net::HTTP.new @uri.host, @uri.port # , "localhost", "8000"
      @http.use_ssl = true
      # @http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      # @http.cert_store = OpenSSL::X509::Store.new
      # ca_file = "/Users/andrej/Library/Preferences/httptoolkit/ca.pem"
      # @http.cert_store.set_default_paths
      # @http.cert_store.add_file ca_file
      if RUBY_VERSION.to_f > 3.0
        @http.ssl_version = :TLSv1_2 # rubocop:disable Naming/VariableNumber
      end
      @http.read_timeout = 120
      if (form_resp = get_page)
        # doc = Nokogiri::HTML page_resp(form_resp, text).body
        doc = Nokogiri::HTML page_resp(form_resp, text).body
        @array = doc.css("div.viewHover").map { |item| hit item }
      end
    end

    private

    # @param location [String]
    # @param deeep [Integer]
    # @return [String, nil]
    def get_page(location = "/", deep = 0)
      return if deep > 3

      req = Net::HTTP::Get.new location
      set_headers req
      resp = @http.request req
      resp.get_fields("set-cookie")&.each { |v| @jar.parse v, @uri }
      return resp if resp.code == "200"

      request_uri = URI.parse(resp["location"]).request_uri
      get_page request_uri, deep + 1
    end

    # rubocop:disable Metrics/MethodLength

    # @param form [Nokogiri::HTML::Document]
    # @param text [String]
    # @return [Array<String>]
    def form_data(form, text) # rubocop:disable Metrics/CyclomaticComplexity
      fd = form.xpath(
        "//input[@type!='radio']|" \
        "//input[@type='radio'][@checked]|" \
        "//select[@name!='view:_id1:_id2:cbLang']|" \
        "//textarea",
      ).reduce([]) do |m, i|
        v = case i[:name]
            when "view:_id1:_id2:txtSymbol" then text
            when "view:_id1:_id2:rgTrunc", "view:_id1:_id2:cbSort" then "R"
            when "view:_id1:_id2:cbType" then "FP"
            when "$$xspsubmitid" then "view:_id1:_id2:_id131"
            when "$$xspsubmitscroll" then "0|102"
            when "view:_id1" then "view:_id1"
            else i[:value]
            end
        m << %{--#{BOUNDARY}}
        m << %{Content-Disposition: form-data; name="#{i[:name]}"\r\n\r\n#{v}}
      end
      fd << %{--#{BOUNDARY}--\r\n}
    end
    # rubocop:enable Metrics/MethodLength

    # @param form_resp [Net::HTTPOK]
    # @param text [String]
    # @return [Net::HTTPOK]
    def page_resp(form_resp, text) # rubocop:disable Metrics/AbcSize
      form = Nokogiri::HTML form_resp.body
      req = Net::HTTP::Post.new form.at("//form")[:action]
      set_headers req
      req["Content-Type"] = "multipart/form-data; boundary=#{BOUNDARY}"
      req.body = form_data(form, text).join("\r\n")
      resp = @http.request req
      get_page Addressable::URI.parse(resp["location"]).request_uri
    end

    # @param item [Nokogiri::XML::Element]
    # @return [RelatonUn::Hit]
    def hit(item)
      Hit.new(hit_data(item), self)
    end

    # @param item [Nokogiri::XML::Element]
    # @return [Hash]
    def hit_data(item) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
      en = item.at("//span[.='ENGLISH']/../..")
      {
        ref: item.at("div/div/a")&.text&.sub("\u00A0", ""),
        symbol: symbol(item),
        title: item.at("div/div/span")&.text,
        keyword: item.at("div[3]/div[5]/span")&.text,
        date_pub: date_pub(item),
        date_rel: date_rel(en),
        link: link(en),
        session: session(item),
        agenda: agenda(item),
        distribution: distribution(item),
        job_number: job_number(item),
      }
    end

    # @param item [Nokogiri::XML::Element]
    # @return [String]
    def symbol(item)
      item.xpath(
        "div/div[not(contains(@class, 'hidden'))]/"\
        "label[contains(.,'Symbol')]/following-sibling::span[1]",
      ).map &:text
    end

    # @param item [Nokogiri::XML::Element]
    # @return [String]
    def date_pub(item)
      item.at("//label[.='Publication Date: ']/following-sibling::span")&.text
    end

    # @param item [Nokogiri::XML::Element]
    # @return [String]
    def date_rel(item)
      item.at("./following-sibling::span[contains(@id, 'cfRelDateE')]")&.text
    end

    # @param item [Nokogiri::XML::Element]
    # @return [Array<Hash>]
    def link(item)
      item.xpath("//a[contains(@title, 'Open')]").map do |l|
        {
          content: l[:href],
          type: l[:title].match(/PDF|Word/).to_s.downcase,
        }
      end
    end

    # @param item [Nokogiri::XML::Element]
    # @return [String]
    def session(item)
      item.at("//label[.='Session / Year:']/following-sibling::span")&.text
    end

    # @param item [Nokogiri::XML::Element]
    # @return [String]
    def agenda(item)
      item.at("//label[.='Agenda Item(s):']/following-sibling::span")&.text
    end

    # @param item [Nokogiri::XML::Element]
    # @return [String]
    def distribution(item)
      item.at("//label[.='Distribution:']/following-sibling::span")&.text
    end

    def job_number(item)
      item.at("//span[contains(@id, 'cfJobNumE')]")&.text
    end

    # rubocop:disable Metrics/MethodLength

    # @param req [Net::HTTP::Get, Net::HTTP::Post]
    def set_headers(req) # rubocop:disable Metrics/AbcSize
      set_cookie req
      req["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9," \
                      "image/avif,image/webp,image/apng,*/*;q=0.8," \
                      "application/signed-exchange;v=b3;q=0.9"
      req["Accept-Encoding"] = "gzip, deflate, br"
      req["Accept-Language"] = "en-US;q=0.8,en;q=0.7"
      req["Cache-Control"] = "max-age=0"
      req["Connection"] = "keep-alive"
      req["Origin"] = "https://documents.un.org"
      req["Referer"] = "https://documents.un.org/prod/ods.nsf/home.xsp"
      req["Sec-Fetch-Dest"] = "document"
      req["Sec-Fetch-Mode"] = "navigate"
      req["Sec-Fetch-Site"] = "same-origin"
      req["Sec-Fetch-User"] = "?1"
      req["Upgrade-Insecure-Requests"] = "1"
      req["User-Agent"] = AGENT
    end
    # rubocop:enable Metrics/MethodLength

    # @param req [Net::HTTP::Get, Net::HTTP::Post]
    def set_cookie(req)
      req["Cookie"] = HTTP::Cookie.cookie_value @jar.cookies(@uri)
    end
  end
end
