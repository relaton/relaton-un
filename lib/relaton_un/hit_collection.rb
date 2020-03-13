# frozen_string_literal: true

require "net/http"
require "http-cookie"

module RelatonUn
  # Page of hit collection.
  class HitCollection < RelatonBib::HitCollection
    AGENT = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.130 Safari/537.36"
    DOMAIN = "https://documents.un.org"
    BOUNDARY = "----WebKitFormBoundary6hkaBvITDck8dHCn"

    # @param text [String] reference to search
    def initialize(text)
      super
      @uri = URI.parse DOMAIN
      @jar = HTTP::CookieJar.new
      @http = Net::HTTP.new @uri.host, @uri.port
      @http.use_ssl = true
      if (form_resp = get_page)
        form = Nokogiri::HTML form_resp.body
        form_data = form.xpath(
          "//input[@type!='radio']",
          "//input[@type='radio'][@checked]",
          "//select[@name!='view:_id1:_id2:cbLang']",
          "//textarea"
        ).reduce([]) do |m, i|
          v = case i[:name]
              when "view:_id1:_id2:txtSymbol" then text
              when "view:_id1:_id2:cbType" then "FP"
              when "view:_id1:_id2:cbSort" then "R"
              when "$$xspsubmitid" then "view:_id1:_id2:_id130"
              when "$$xspsubmitscroll" then "0|167"
              else i[:value]
              end
          m << %{--#{BOUNDARY}}
          m << %{Content-Disposition: form-data; name="#{i[:name]}"\r\n\r\n#{v}}
        end
        form_data << %{--#{BOUNDARY}--\r\n}
        req = Net::HTTP::Post.new form.at("//form")[:action]
        set_headers req
        req["Content-Type"] = "multipart/form-data, boundary=#{BOUNDARY}"
        req.body = form_data.join("\r\n")
        resp = @http.request req
        page_resp = get_page URI.parse(resp["location"]).request_uri
        doc = Nokogiri::HTML page_resp.body
        @array = doc.css("div.viewHover").map do |item|
          ref = item.at("div/div/a")&.text&.sub "\u00A0", ""
          title = item.at("div/div/span")&.text
          keyword = item.at("div[3]/div[5]/span")&.text
          date_pub = item.at("//label[.='Publication Date: ']/following-sibling::span")&.text
          en = item.at("//span[.='ENGLISH']/../..")
          date_rel = en.at("./following-sibling::span[contains(@id, 'cfRelDateE')]").text
          link = en.xpath("//a[contains(@title, 'Open')]").map do |l|
            { content: l[:href], type: l[:title].match(/PDF|Word/).to_s.downcase }
          end
          Hit.new({
            ref: ref,
            title: title,
            keyword: keyword,
            date_pub: date_pub,
            date_rel: date_rel,
            link: link
          }, self)
        end
      end
    end

    private

    # @param location [String]
    # @param deeep [Integer]
    # @return [Strinf, NilClass]
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

    def set_headers(req)
      set_cookie req
      req["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9"
      req["Accept-Encoding"] = "gzip, deflate, br"
      req["Cache-Control"] = "max-age=0"
      req["Connection"] = "keep-alive"
      req["Origin"] = "https://documents.un.org"
      req["Referer"] = "https://documents.un.org/prod/ods.nsf/home.xsp"
      req["Sec-Fetch-Mode"] = "navigate"
      req["Sec-Fetch-Site"] = "same-origin"
      req["Sec-Fetch-User"] = "?1"
      req["Upgrade-Insecure-Requests"] = "1"
      req["User-Agent"] = AGENT
    end

    def set_cookie(req)
      req["Cookie"] = HTTP::Cookie.cookie_value @jar.cookies(@uri)
    end
  end
end
