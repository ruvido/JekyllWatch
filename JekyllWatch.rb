#!/usr/bin/env ruby

require 'fileutils'

# -----------------------------------
# CLASS DEFINITION
# -----------------------------------
class Draft
  attr_accessor :filename, :basename, :title, :author, :date, :slug, :header, 
                :jkname, :preview, :preview_field, :publish, :publish_field,
                :config
  def initialize(filename,configdata)
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
    @config   = configdata

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

    new_filename = config.blog_previews + File.basename(filename)
    FileUtils.cp( filename, new_filename )

    return new_filename
  end
  # --------------------------------
  def to_posts
    # post_dir = $blog_dir + "/_posts/"
    # prev_dir = $blog_dir + "/previews/"

    new_filename = config.blog_posts + jkname
    FileUtils.cp( filename, new_filename )
    puts "file copied to posts"
    
    old_preview = config.blog_previews + File.basename(filename)
    if File.file?(old_preview)
      FileUtils.rm( old_preview )
      puts "preview is deleted"
    end

    return new_filename
  end 
end
# ======================================
# CONFIG CLASS
# ======================================
class Dataconfig
  attr_accessor :dump, :dump_drafts, :dump_previews, :dump_posts,
                :blog, :blog_previews, :blog_posts, :blog_images

  def initialize(configfile)
    @filename         = configfile
    @dump             = ''
    @dump_drafts      = ''
    @dump_previews    = ''
    @dump_posts       = ''
    @blog             = ''
    @blog_previews    = ''
    @blog_posts       = ''
    @blog_images      = ''
    @blog             = ''

    config = File.read(@filename)
    config.split("\n").each do |line|
      k,v=line.split(":")
      # puts k, v
      if k =~ /dump/
        # .strip removes any extra space from the dir path
        @dump         = "#{v.strip}/"
        @dump_drafts  = "#{@dump}/drafts/"
        @dump_previews= "#{@dump}/previews/"
        @dump_posts   = "#{@dump}/published/"
        FileUtils::mkdir_p @dump unless Dir.exist?(@dump)
        FileUtils::mkdir_p @dump_drafts unless Dir.exist?(@dump_drafts) 
        FileUtils::mkdir_p @dump_previews unless Dir.exist?(@dump_previews) 
        FileUtils::mkdir_p @dump_posts unless Dir.exist?(@dump_posts) 
      end
      if k =~ /blog/
        # .strip removes any extra space from the dir path
        @blog         = "#{v.strip}/"
        @blog_previews= "#{@blog}/previews/"
        @blog_posts   = "#{@blog}/_posts/"
        @blog_images  = "#{@blog}/images/posts/"
        FileUtils::mkdir_p @blog unless Dir.exist?(@blog)
        FileUtils::mkdir_p @blog_previews unless Dir.exist?(@blog_previews)
        FileUtils::mkdir_p @blog_posts unless Dir.exist?(@blog_posts)
        FileUtils::mkdir_p @blog_images unless Dir.exist?(@blog_images)
      end
    end
  end
end

class Item
  def initialize(item_name, quantity)
    @item_name = item_name
    @quantity = quantity
  end
end


# -----------------------------------
# READ CONFIG FILE
# -----------------------------------

# $dump_dir = ''
# $blog_dir = ''

# configfile = ARGV.first
conf=Dataconfig.new (ARGV.first)

# exit

# puts conf.blog, conf.blog_previews, conf.blog_posts, conf.blog_images
# puts '-------'
# puts conf.dump, conf.dump_drafts, conf.dump_previews, conf.dump_posts 

# exit


# config = File.read(configfile)
# config.split("\n").each do |line|
#   k,v=line.split(":")
#   # puts k, v
#   if k =~ /dump/
#     # .strip removes any extra space from the dir path
#     $dump_dir = v.strip
#   end
#   if k =~ /blog/
#     # .strip removes any extra space from the dir path
#     $blog_dir = v.strip
#   end
#   if k=~ /previews/
#     dump_previews = v.strip
#   end
#   if k=~ /published/
#     dump_posts = v.strip
#   end
# end

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
# Dir.glob( conf.dump + "*.md").each do |draftname|
# drafts = Dir[File.join(conf.dump, '**', '*.{md}')]

# Find all md files in subdirectories excluding the ones in 
# directories starting with a "_" character. Those are protected.
# This can be used to store template md files.

Dir["#{conf.dump}{[!_]**/*,*}.md"].each do |ii|

  puts '--------------------------------'

  draft=Draft.new(ii,conf)
  status = draft.status
  puts draft.basename, status

  case status
  when "publish"
    draft.to_posts
    puts "file published!"
  when "preview"
    draft.to_previews
    puts "file sent to previews, want the address?"
    draft.missing
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
# 4. if a directory starts with "_" in the dump directory IGNORE it
