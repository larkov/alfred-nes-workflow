#!/usr/bin/env ruby

require 'json'
require 'httparty'

country = ENV['country'] && ENV['country'] != "" ? ENV['country'].upcase : "GB"
rows = ENV['rows'] && ENV['rows'] != "" ? ENV['rows'] : 3

out = Hash.new
out['items']= []

query=ARGV[0]

case country
when "AT"
  URL="https://www.nintendo.at"
when "BE"
  URL="https://www.nintendo.be/fr"
when "CH"
  URL="https://www.nintendo.ch/de"
when "ES"
  URL="https://www.nintendo.es"
when "DE"
  URL="https://www.nintendo.de"
when "FR"
  URL="https://www.nintendo.fr"
when "IT"
  URL="https://www.nintendo.it"
when "NL"
  URL="https://www.nintendo.nl"
when "PT"
  URL="https://www.nintendo.pt"
when "RU"
  URL="https://www.nintendo.ru"
when "ZA"
  URL="https://www.nintendo.co.za"
else
  URL="https://www.nintendo.co.uk"
end

searchurl = "https://search.nintendo-europe.com/en/select?q=#{query}&fq=type:GAME AND ((playable_on_txt:\"HAC\")) AND (dates_released_dts:[* TO NOW] AND nsuid_txt:*)&start=0&rows=#{rows}&wt=json"

response = HTTParty.get(searchurl)

resp = JSON.parse(response.body)

items = resp['response']['docs']

itemlist = ""
items.each_with_index do |item, index|
  index == 0 ? itemlist = "#{item["nsuid_txt"][0]}" : itemlist = "#{itemlist},#{item["nsuid_txt"][0]}"
end
#puts itemlist
url="https://api.ec.nintendo.com/v1/price?country=#{country}&lang=en&ids=#{itemlist}"

prices = JSON.parse(HTTParty.get(url).body)["prices"]


items.each do |item|
  title="#{item["title"]}"
  # puts title
  itemid = item["nsuid_txt"][0]
  # puts itemid.class

  # puts title
  price ="unknown"
  if country != ""
    itemprice = prices.detect{ |i| i["title_id"].to_s == itemid}
    # puts itemprice.class
    if itemprice["discount_price"]
      # price = "Discount price: #{prices["discount_price"]["amount"]}"
      price="Discount price: #{itemprice["discount_price"]["amount"]} Ends: #{itemprice["discount_price"]["end_datetime"][0..9]} Regular Price: #{itemprice["regular_price"]["amount"]}"
    else
      price="Price: #{itemprice["regular_price"]["amount"]}"
    end
  else
    price ="#{item["price_sorting_f"]}"
  end
  # arg = "#{URL}#{item["url"]}"
  # itemid=item["nsuid_txt"][0]
  # title="https://api.ec.nintendo.com/v1/price?country=#{country}&lang=en&ids=#{itemid}"
  # arg = item["url"]
  arg = "#{URL}#{item["url"]}"
  out["items"].push({"type" => "default", "title" => "#{title}", "subtitle" => "#{price}", "arg" => arg})
end.empty? and begin
  out["items"].push({"type" => "default", "title" => "No results found."})
end

print out.to_json