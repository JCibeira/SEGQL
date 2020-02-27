#!/usr/bin/ruby
require 'uri'
require 'json'
require 'net/http'

def validate_values(values, valid_values)
    values.each do |value|
        if !valid_values.include?(value)
            return false
        end
    end
    return true
end

def validate_url(url)
    return url =~ URI::regexp
end

def get_request(base_url, function, query_string, params)
    url = URI.parse(base_url + function)
    req = Net::HTTP::Get.new(url.to_s)
    req.set_form_data(params)
    req = Net::HTTP::Get.new(url.path + '?' + req.body)
    res = Net::HTTP.start(url.host, url.port) {
        |http| http.request(req)
    }
    return res.body
end

def select_blocks(base_url, attributes, segment_params)
    # open_response = JSON.parse(get_request(base_url, '/open', false, {}))
    # segment_params[":key"] = open_response["key"]
    segment_params[":key"] = 63
    segment_response = get_request(base_url, '/segment', true, segment_params)
    puts segment_response
end

def merge_blocks(attributes, url)
    puts 'merge_blocks'
end


base_url = 'http://bom.ciens.ucv.ve/api/'
valid_attrs = ['*', 'bid', 'label', 'text', 'images', 'pa', 'density', 'area', 'rectangle', 'parent']
valid_params = ['url', 'key', 'categories', 'area', 'pa', 'dc', 'method', 'granmethod', 'align']
segment_params = {
    'ptype' => 'ffront', 
    'dc' => 30,
    'area' => 0,
    'categories' => 'FLOW',
    'method' => 'html5',
    'granmethod' => 'frec',
    'align' => 'HVL',
    'pa' => 5
}

# Lectura de lineas obligatorias
function = gets.chomp
attributes = gets.chomp
from = gets.chomp
url = gets.chomp

attributes.delete!(' ')
attributes = attributes.split(',')

last_line = url.include?(';')
error = false
actual_line = 0

condition = ""
order_by = ""
params = ""

# Lectura de lineas opcionales
if last_line
    url.delete!(';')
else
    while !last_line
        line_func = gets.chomp
        line_val = gets.chomp
        if line_func === 'where' && actual_line === 0
            # Procesar where
            actual_line = 1
            if line_val.include?(';')
                line_val.delete!(';')
                last_line = true
            end
            condition = line_val
        elsif line_func === 'order by' && actual_line <= 1
            # Procesar order by
            actual_line = 2
            if line_val.include?(';')
                line_val.delete!(';')
                last_line = true
            end
            order_by = line_val
        elsif line_func === 'params' && actual_line <= 2
            # Procesar params
            if line_val.include?(';')
                line_val.delete!(';')
                last_line = true
                params = line_val
            else
                last_line = true
                error = true
            end
        else
            last_line = true
            error = true
        end
    end
end

if !error
    if function === 'select'
        if validate_values(attributes, valid_attrs)
            if validate_url(url)
                segment_params[":url"] = url
                select_blocks(base_url, attributes, segment_params)
            else
                puts 'URL no válida'
            end
        else
            puts 'Atributos no válidos'
        end
    elsif function === 'merge'
        merge_blocks(attributes, url)
    else
        puts 'Función no válida'
    end
else
    puts 'Consulta no válida'
end