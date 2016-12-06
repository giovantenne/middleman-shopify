require "dato"
require "byebug"
require "shopify_api"

client = Dato::Site::Client.new("60fe1ed5c8bba61e8236d636fc2c0ab7b2c6a2053b5415f204")
loader = Dato::Local::Loader.new(client)
loader.load
dato = loader.items_repo
shop_url = "https://6dcd2e2319963f65366532c3b7cc9b91:070a2541296c65252972a309bc884ca5@bkl14308.myshopify.com/admin"
ShopifyAPI::Base.site = shop_url

ShopifyAPI::Product.all.each do |product|
  dato_product = dato.products.find { |p| p.shopify_id == product.id.to_s }
  if dato_product
    if product.updated_at < dato_product.updated_at
      puts "Aggiorno (#{product.id})"
      product.title = dato_product.title
      product.body_html = dato_product.description
      product.variants[0].price = dato_product.price
      product.images = []
      product.images = [ { src: dato_product.photo.url } ]
      product.save
    end
  else
    puts "Elimino #{product.title} (#{product.id})"
    product.destroy
  end
end

loader.load
dato = loader.items_repo

to_add = dato.products.select { |product| product.shopify_id.blank? }
to_add.each do |item|
  new_product = ShopifyAPI::Product.new
  new_product.title = item.title
  new_product.body_html = item.description
  new_product.variants = [ { price:  item.price } ]
  new_product.images = [ { src: item.photo.url } ]
  # new_product.published_scope = "global"
  new_product.published = true
  new_product.save
  puts "Creo #{item.title} (#{new_product.id})"
  i = client.items.find(item.id)
  client.items.update(item.id, i.merge("shopify_id" => new_product.id.to_s))
end





