#!/usr/bin/env ruby

# ===================
# NOTES
# ===================
# - Files in the published folder are "frozen" and not copied to the blog anymore

require 'fileutils'
require 'git'

# -----------------------------------
# CLASS DEFINITION
# -----------------------------------
class Draft
  attr_accessor :filename, :basename, :title, :author, :date, :slug, :header, :image,
                :jkname, :preview, :preview_field, :publish, :publish_field,
                :config
  def initialize(filename,blog)
    @filename = filename
    @basename = File.basename(filename)
    @header   = false
    @image    = false
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
    @config   = blog

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
        if k == "image"
          @image=v.strip
        end
      end
    end
  end
  # --------------------------------
  def status
    if @publish_field==true and @date!="" and @slug!="" and @title!=""
      status_v = 'publish' 
      if image and !File.file?("#{File.dirname(filename)}/#{image}")
        status_v = 'preview' 
      end
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
    if @image and !File.file?("#{File.dirname(filename)}/#{image}")
      puts "ERR: image is missing"      
    end
    if @publish_field == ''
      puts "WAR: publish field is missing"
    end

    # else
    #   puts "OK: article ready"
    # end  
  end
  # --------------------------------
  def to_previews

    new_filename = "#{config.blog_previews}/#{basename}"
    FileUtils.cp( filename, new_filename )

    new_filename = "#{config.dump_previews}/#{basename}"
    FileUtils.mv( filename, new_filename ) unless filename == new_filename
    # FileUtils.mv( filename, "#{config.dump_trash}/#{basename}__#{time.usec}")

    if image

      old_image = "#{File.dirname(filename)}/#{image}"
      new_image = "#{config.dump_previews}/#{image}"

      if File.file?(old_image) and old_image != new_image
        FileUtils.mv( old_image, new_image ) 
      end

    end 


    return new_filename
  end
  # --------------------------------
  def to_posts
    # post_dir = $blog_dir + "/_posts/"
    # prev_dir = $blog_dir + "/previews/"

    # new_filename = "#{config.blog_posts}/#{jkname}"
    # new_filename = config.blog_posts + jkname
    FileUtils.cp( filename, "#{config.blog_posts}/#{jkname}" )
    
    # old_preview = config.blog_previews + File.basename(filename)
    old_preview = "#{config.blog_previews}/#{basename}"
    if File.file?(old_preview)
      FileUtils.rm( old_preview )
    end

    new_filename = "#{config.dump_posts}/#{jkname}"
    FileUtils.mv( filename, new_filename ) unless filename == new_filename

    if image

      old_image = "#{File.dirname(filename)}/#{image}"
      new_image = "#{config.blog_images}/#{image}"
      FileUtils.cp( old_image, new_image )
      new_image = "#{config.dump_images}/#{image}"
      FileUtils.mv( old_image, new_image ) unless old_image == new_image



      # if File.file?(old_image) and old_image != new_image
      #   FileUtils.mv( old_image, new_image ) 
      #   puts "image mossa"
      # end

    end 

    return new_filename
  end 
end
# ======================================
# Blog CLASS
# ======================================
class Blogdata
  attr_accessor :dump, :dump_drafts, :dump_previews, :dump_posts, :dump_images,
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
        @dump         = "#{v.strip}"
        @dump_drafts  = "#{@dump}/drafts"
        @dump_previews= "#{@dump}/previews"
        @dump_posts   = "#{@dump}/published"
        @dump_images  = "#{@dump_posts}/images" 
        FileUtils::mkdir_p @dump unless Dir.exist?(@dump)
        FileUtils::mkdir_p @dump_drafts unless Dir.exist?(@dump_drafts) 
        FileUtils::mkdir_p @dump_previews unless Dir.exist?(@dump_previews) 
        FileUtils::mkdir_p @dump_posts unless Dir.exist?(@dump_posts)
        FileUtils::mkdir_p @dump_images unless Dir.exist?(@dump_images) 
      end
      if k =~ /blog/
        # .strip removes any extra space from the dir path
        @blog         = "#{v.strip}"
        @blog_previews= "#{@blog}/previews"
        @blog_posts   = "#{@blog}/_posts"
        @blog_images  = "#{@blog}/images/posts"
        FileUtils::mkdir_p @blog unless Dir.exist?(@blog)
        FileUtils::mkdir_p @blog_previews unless Dir.exist?(@blog_previews)
        FileUtils::mkdir_p @blog_posts unless Dir.exist?(@blog_posts)
        FileUtils::mkdir_p @blog_images unless Dir.exist?(@blog_images)
      end
    end
  end
  def push
    # g = Git.open( conf.blog , :log => Logger.new(STDOUT))
    # g = Git.open( conf.blog )
    # puts g.status
    # g.add(:all=>true) unless g.status.untracked == {}
    # puts g.status.changed
    # g.commit_all('message')
    # g.push
    # g = Git.open( @blog )
    # if g.status.changed != {} or g.status.untracked != {}
    #   puts g.status.changed
    #   puts g.status.untracked
    # #   g.add(:all=>true)
    #   g.commit('message')
    # #   g.push
    #   puts 'changes pushed'
    # else
    #   puts 'no changes'
    # end

    # gitmessage = system ( "cd #{blog}; git add * ; git commit -a -m 'cc'>caz" )
    Dir.chdir @blog
    # puts `git status`
    # msg1 = "Changes not staged for commit:"
    `git add --all .`
    if `git commit -a -m 'commit'` =~ /nothing to commit, working directory clean/
      puts 'nothing to commit'
    else
      `git push`
      puts 'push blog forward!'
    end
  end
end


# -----------------------------------
# 
# -----------------------------------
# 
# -----------------------------------


if ARGV.empty?
  puts """

  jekyllwatch : missing argument! - configfile

  """
end

myblog=Blogdata.new (ARGV.first)

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

# Dir["#{conf.dump}/{[!_]**/*,*}.md"].each do |ii|

#   draft=Draft.new(ii,conf)

#   puts draft.basename
#   puts draft.image

# end

# exit

[ myblog.dump_previews, myblog.dump_drafts ].each do |cdir|

  Dir["#{cdir}/{[!_]**/*,*}.md"].each do |ii|

    puts '--------------------------------'

    draft=Draft.new(ii,myblog)
    status = draft.status
    puts draft.basename, draft.filename, draft.image, status

    case status
    when "publish"
      draft.to_posts
      puts "file published!"
    when "preview"
      draft.missing
      draft.to_previews
      # puts "file sent to previews, want the address?"
    when "draft"
      puts "keep working on that!"
    end    

  end
  puts '--------------------------------'
end

# sleep 1
myblog.push




# ===================
# TODO
# ===================
# - send email report
# ===================
