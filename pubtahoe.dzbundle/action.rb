# Dropzone Action Info
# Name: PubTahoe
# Description: Upload to locally running tahoe-lafs (https://tahoe-lafs.org) and get a shortlink from a pubtahoe (https://github.com/habnabit/pubtahoe)
# Handles: Files
# Creator: tBunnyMan
# URL: http://bunnyman.info
# Events: Dragged, clicked
# KeyModifiers: Option
# SkipConfig: No
# RunsSandboxed: Yes
# Version: 2.0
# MinDropzoneVersion: 3.0

require "net/https"

def dragged
  tahoepub = "https://skwrl.es"
  tahoeuri = URI.parse('http://127.0.0.1:3456/uri')
  mycap = nil
  ext = nil

  puts $items.inspect
  if $items.length == 1
    $dz.begin("Uploaded single file")
    $dz.percent(10)

    item = $items[0]
    ext = File.extname(item).downcase

    mycap = upload_file(item, tahoeuri)
    $dz.percent(50)
  else
    $dz.begin("Uploading #{$items.length} Files")
    $dz.percent(10)
    percent = 10
    inc = 80 / ($items.length + 1)
    mycap = make_directory(tahoeuri)
    puts "New FolderCap: #{mycap}"
    $dz.percent(percent += inc)
    $items.each do |item|
      filecap = upload_file(item, tahoeuri, mycap)
      puts "File #{item} uploaded with cap #{filecap}"
      $dz.percent(percent += inc)
    end
  end

  $dz.percent(90)
  puts "Final cap #{mycap} with ext #{ext}"
  short_url = get_short_tahoe(mycap, ext, URI.parse(tahoepub))
  puts short_url.inspect

  $dz.percent(100)
  $dz.finish("Enjoy")
  $dz.url(tahoepub + short_url)
end

def make_directory(uri)
  http = Net::HTTP.new(uri.host, uri.port)
  req_uri = uri.request_uri + "?t=mkdir"
  request = Net::HTTP::Post.new(req_uri)
  response = http.request(request)
  puts response.inspect
  return response.body
end

def upload_file(file, uri, folder=nil)
  http = Net::HTTP.new(uri.host, uri.port)
  req_uri = uri.request_uri
  if not folder.nil?
    req_uri += URI.encode("/%s/%s" % [folder, File.basename(file)])
    puts req_uri.inspect
  end
  request = Net::HTTP::Put.new(req_uri)
  request.body = File.read(file)
  response = http.request(request)
  puts response.inspect
  return response.body
end

def get_short_tahoe(cap, ext, puburi)
  params = {:api => "y", :ext => ext, :uri => cap}
  https = Net::HTTP.new(puburi.host, puburi.port)
  https.use_ssl = true
  req = Net::HTTP::Post.new(puburi.request_uri)
  req.set_form_data(params)
  response = https.request(req)
  puts response.inspect
  return response.body
end

def clicked
  # This method gets called when a user clicks on your action
  system("open http://127.0.0.1:3456")
end
