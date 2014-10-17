

require 'pg'
require 'json'


conn = PG::Connection.open(
    :host =>     '127.0.0.1',
    :port =>     5432,
    :dbname =>   'vocab',
    :user =>    'contr_vocab_db',
    :password => 'contr_vocab_db'
)


res = conn.exec('SELECT 1 AS a, 2.2 AS b, NULL AS c')
res.getvalue(0,0) # '1'
res[0]['b']       # '2'
res[0]['c']       # nil

# can we get the type,

# there is index

puts "type #{ res.ftype( 0 ) }" 

res.fields().each do |field|
	puts "field '#{field}'  -> #{res[0][field]}"
end

puts "---------------"
puts "res.nfields #{ res.nfields }"


# for i in 0..res.nfields - 1
# 	fname = res.fname(i)
# 	type = conn. exec( "SELECT format_type($1,$2)", [res.ftype(i), res.fmod(i)] ).getvalue( 0, 0 )
# 	puts "fname: '#{fname}'  type #{type} "
# end

# ok, maybe we actually want the result set ... without remapping anything ? 

res.each do |row|
	for i in 0..res.nfields - 1
		fname = res.fname(i)
		type = conn. exec( "SELECT format_type($1,$2)", [res.ftype(i), res.fmod(i)] ).getvalue( 0, 0 )
		puts "fname: '#{fname}'  type #{type} value #{row[fname]}"
	end
end

# gives us the field type 


