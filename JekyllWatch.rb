#!/usr/bin/env ruby

require 'fileutils'

# -----------------------------------
# CLASS DEFINITION
# -----------------------------------
class Draft
  attr_accessor :filename, :basename, :title, :author, :date, :slug, :header, 
                :jkname, :preview, :preview_field, :publish, :publish_field
  def initialize(filename)
    @filename = filename
    @basename = File.basename(filename)
    @header   = false
    @title    = ''
    @author   = ''
    @date     = ''
    @slug     = ''
    @preview  = false
    @publish  = false
    @preview_field  = ''
    @publish_field  = ''
    @jkname   = 'Untitled.md'
    @status_v = 'draft'

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
  # --------------------------------
  def status
    if @publish_field==true and @date!="" and @slug!="" and @title!=""
      status_v = 'publish'
      @jkname = date + "-" + slug + ".md"
    elsif preview_field == true
      status_v = 'preview'
    else
      status_v = 'draft'
    end
    return status_v
  end
  def missing
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
    # else
    #   puts "OK: article ready"
    # end  
  end
  # --------------------------------
  def to_previews
    prev_dir = $blog_dir + "/previews/"

    new_filename = prev_dir + File.basename(filename)
    FileUtils.cp( filename, new_filename )

    return new_filename
  end
  # --------------------------------
  def to_posts
    post_dir = $blog_dir + "/_posts/"
    prev_dir = $blog_dir + "/previews/"

    new_filename = post_dir + jkname
    FileUtils.cp( filename, new_filename )
    puts "file copied to posts"
    
    old_preview = prev_dir + File.basename(filename)
    if File.file?(old_preview)
      FileUtils.rm( old_preview )
      puts "preview is deleted"
    end

    return new_filename
  end 
end

# -----------------------------------
# READ CONFIG FILE
# -----------------------------------

$dump_dir = ''
$blog_dir = ''

configfile = ARGV.first
config = File.read(configfile)
config.split("\n").each do |line|
  k,v=line.split(":")
  # puts k, v
  if k =~ /dump/
    # .strip removes any extra space from the dir path
    $dump_dir = v.strip
  end
  if k =~ /blog/
    # .strip removes any extra space from the dir path
    $blog_dir = v.strip
  end
  if k=~ /previews/
    dump_previews = v.strip
  end
  if k=~ /published/
    dump_posts = v.strip
  end
end

# GLOBAL VARIABLES -----------------
# $post_dir = $blog_dir + "/_posts/"
# $prev_dir = $blog_dir + "/previews/"


# --------------------
# WARNING!!!
# CHECK IF THOSE DIRECTORIES ACTUALLY EXIST!
# --------------------
# puts dump_dir, blog_dir, post_dir, prev_dir


# -----------------------------------
# COLLECT ALL DRAFTS
# -----------------------------------
draftlist=[]
Dir.glob($dump_dir+"/*.md").each do |draftname|
  draftlist.push(Draft.new(draftname))
end

draftlist.each do |ii|
  puts '--------------------------------'

  status = ii.status
  puts ii.basename, status

  case status
  when "publish"
    ii.to_posts
    puts "file published!"
  when "preview"
    ii.to_previews
    puts "file sent to previews, want the address?"
    ii.missing
  when "draft"
    puts "keep working on that!"
  end    

end
puts '--------------------------------'

# ===================
# TODO
# ===================

# 1. check if image EXIST
# 2. mv files in the dump directory according to "_preview" or "_published"
# 3. from preview or published back to drafts if needed
