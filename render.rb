#!/usr/bin/ruby

# Example Usage,
# ./render.rb -t AODNParameterVocabulary.erb


require 'erb'
require 'pg'
require 'optparse'


def map_query( conn, query, args, &code )
  # map a proc/block over postgres query result
  xs = []
  conn.exec( query, args ).each do |row|
    xs << code.call( row )
  end
  xs
end


class RDFBinding

  # we avoid building an intermediate data structure, and instead just expose an
  # interface for the template to directly query the rdf view

  def initialize( conn, date, os)
    @conn = conn
    @date = date
    @os = os
    # @buf = ""
  end



  def query_sql_subject( query, args )
    # supports composing general sql queries and returns the subject row
    map_query( @conn, query, args) do |row|
      # row['target'].encode(:xml => :text)
      row['subject'].encode(:xml => :text)
    end
  end

#   inline exapanded queries despite giving the optimiser a better look
#   at the data, don't appear to run any faster
#
#   def query_rdf_objects( predicate, subject )
#     map_query( @conn, "select object from _rdf where predicate = $$#{predicate}$$ and subject = $$#{ subject }$$", nil) do |row|
#       row['object']
#     end
#   end
#
#   def query_rdf_subjects( predicate, object )
#     map_query( @conn, "select subject from _rdf where predicate = $$#{predicate}$$ and object = $$#{object}$$", nil) do |row|
#       row['subject']
#     end
#   end


  def query_rdf_objects( predicate, subject )
    map_query( @conn, %{
      select object from _rdf_m where predicate = $1 and subject = $2
      }, [predicate, subject]) do |row|
      row['object'].encode(:xml => :text)
    end
  end

  def query_rdf_subjects( predicate, object )
    map_query( @conn, %{
      select subject from _rdf_m where predicate = $1 and object = $2
      }, [predicate, object]) do |row|
      row['subject'].encode(:xml => :text)
    end
  end

  def render( filename )
    # we need to use string temporaries, rather than output stream in order to get
    # proper sequencing in the recursive expansion of nested templates
    processed = false
    result = ""
    [ filename, "templates/#{filename}"].each do |path|
      if File.exists?( path)
        # puts "opening #{path}"
        s = ERB.new( File.read(path)).result(binding)
        s = s.gsub /^[ \t]*$\n/, ''
        result += s
        processed = true
        break
      end
    end
    if !processed
      raise "Could not find template '#{filename}'!"
    end
    result
  end

#
#   this approach of using a buffer, and flushing before expanding a nested
#   template doesn't work, because ERB chooses to expand templates, in an inintial
#   pass, before expanding the non nested content so we don't get an opportunity
#   to flush before expanding. 
#
#   def flush_buffer()
#     puts 'flushing'
#     @os.puts @buf 
#     @buf = ""
#   end  
# 
#   def render( filename )
#     # we need to use string temporaries, rather than output stream in order to get
#     # proper sequencing in the recursive expansion of nested templates
#     flush_buffer()
#     processed = false
#     [ filename, "templates/#{filename}"].each do |path|
#       if File.exists?( path)
#         # puts "opening #{path}"
#         s = ERB.new( File.read(path), 0, '>',  'buf' ).result(binding)
#         s = s.gsub /^[ \t]*$\n/, ''
#         @buf += s
#         processed = true
#         break
#       end
#     end
#     if !processed
#       raise "Could not find template '#{filename}'!"
#     end
#     flush_buffer()
#   end
# 



end



options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: example.rb [options]"
  opts.on('-t', '--templatefile NAME', 'templatefile') { |v| options[:template_file] = v }
  opts.on('-h', '--host NAME', 'host')          { |v| options[:host] = v }
  opts.on('-p', '--port NAME', 'port')          { |v| options[:port] = v }
  opts.on('-d', '--database NAME', 'database')  { |v| options[:database] = v }
  opts.on('-u', '--user NAME', 'user')          { |v| options[:user] = v }
  opts.on('-p', '--password NAME', 'password')  { |v| options[:password] = v }
end.parse!
if options[:template_file]

  conn = PG::Connection.open(
    :host =>    options[:host] || '127.0.0.1',
    :port =>    options[:port] || 5432,
    :dbname =>  options[:database] || 'vocab',
    :user =>    options[:user] || 'contr_vocab_db',
    :password => options[:password] || 'contr_vocab_db'
  )

  # need to ensure this doesn't write to anything... 
  $stderr.puts 'refreshing mat view'
  conn.exec( 'refresh materialized view _rdf_m',  nil )
  $stderr.puts 'done'

  context = RDFBinding.new( conn, Time.now, $stdout )
  result = context.render( options[:template_file] )
  $stdout.puts result

  # context.render( options[:template_file] )

else
  puts 'no file specified!'
end




