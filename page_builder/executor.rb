require 'pry'
require 'toml-rb'
require 'erb'

module PageBuilder
  class Executor
    def build
      posts = []
      Dir['posts/*'].each do |filename|
        begin
        post = process(filename, File.read(filename))
        posts.push post
        rescue => e
        end
      end
      posts.each do |post|
        File.write("dist/posts/#{post[:filename]}", post[:html])
      end
    end

    def process(filename, content)
      front_matter = content[0..(content.index('----')-1)]
      content = content[(content.index('----')+5)..-1]
      post = TomlRB.parse(front_matter, symbolize_keys: true)
      post[:filename] = filename[filename.rindex('/')+1..-1]
      b = binding
      b.local_variable_set(:content, content)
      b.local_variable_set(:title, post[:title])
      post[:html] = page_template.result(b)
      return post
    end

    def page_template
      return @post_template if @post_template
      @post_template = ERB.new(File.read('./templates/post.html.erb'))
      return @post_template
    end
  end
end
