#!/usr/bin/env ruby

require 'fileutils'

# -----------------------------------
# CLASS DEFINITION
# -----------------------------------
class Draft
  attr_accessor :filename, :title, :author, :date, :slug, :header, 
                :jkname, :preview, :preview_field, :publish, :publish_field
  def initialize(filename)
    @filename = filename
    @header   = false
    @title    = ''
    @author   = ''
    @date     = ''
    @slug     = ''
    # @ok       = false
    @preview  = false
    @publish  = false
    @preview_field  = ''
    @publish_field  = ''
    @jkname   = 'Untitled.md'

    # ---- Ingest entire file  ----------
    text = File.read(filename)

    # ---- Read header ------------------
    if text.split("\n")[0] == "---"
      @header = true
      splitext = text.split("---")
      head = splitext[1]
      head.split("\n").each do |line|
        k,v=line.split(":")
    # ---------------------------------
        if k =~ /preview/ and v =~ /ok/
          @preview_field=true
        end
    # ---------------------------------
        if k =~ /publish/ and v =~ /ok/
          @publish_field=true
        end
    # ---------------------------------
        if k =~ /date/
          date=v
          d,m,y = v.split('-')
          day   = '%02d' % d
          month = '%02d' % m
          year  = '%04d' % y
          @date=year + "-" + month + "-" + day
        end
    # ---------------------------------
        if k =~ /slug/
          @slug=v.strip
        end
      # ---------------------------------
        if k =~ /title/
          @title=v.strip
        end
      # ---------------------------------
        if k =~ /author/
          @author=v.strip
        end
      end
    end
  end
  def preview
    preview_status = false
    if preview_field == true
      preview_status = true
    end
    return preview_status
  end
  def publish
    publish_status = false
    if @date == ''
      puts "ERR: date is missing"
    end
    if @slug == ''
      puts "ERR: slug is missing"
    end      
    if @title == ''
      puts "ERR: title is missing"
    end      
    if @publish_field == ''
      puts "ERR: publish field is missing"
    end      
    if @publish_field==true and @date!="" and @slug!="" and @title!=""
      publish_status = true
      @jkname = date + "-" + slug + ".md"
    end
    return publish_status
  end
end

# -----------------------------------
# READ CONFIG FILE
# -----------------------------------

dump_dir = ''
blog_dir = ''

configfile = ARGV.first
config = File.read(configfile)
config.split("\n").each do |line|
  k,v=line.split(":")
  # puts k, v
  if k =~ /Dump/
    # .strip removes any extra space from the dir path
    dump_dir = v.strip
  end
  if k =~ /Blog/
    # .strip removes any extra space from the dir path
    blog_dir = v.strip
  end
end

post_dir = blog_dir + "/_posts"
prev_dir = blog_dir + "/previews"


# --------------------
# WARNING!!!
# CHECK IF THOSE DIRECTORIES ACTUALLY EXIST!
# --------------------
# puts dump_dir, blog_dir, post_dir, prev_dir


# -----------------------------------
# COLLECT ALL DRAFTS
# -----------------------------------
draftlist=[]
Dir.glob(dump_dir+"/*.md").each do |draftname|
  draftlist.push(Draft.new(draftname))
end

draftlist.each do |ii|
  puts '--------------------------------'
  puts ii.filename
  puts ii.title
  puts "### ready to preview: "
  puts ii.preview
  puts "### ready to publish: "
  puts ii.publish

  if ii.preview
    # copy file in blog preview folder
    # move file in dump preview folder
    FileUtils.mv('/tmp/your_file', '/opt/new/location/your_file')
    # check for image?
  end

end
puts '--------------------------------'
