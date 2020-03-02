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

def select_blocks(base_url, attributes, segment_params, status)
    #open_response = JSON.parse(get_request(base_url, '/open', false, {}))
    #segment_params['key'] = open_response['key']
    segment_params['key'] = 98
    #segment_response = get_request(base_url, 'segment', true, segment_params)

    #return segment_response.include?(status)
    return true
end

def merge_blocks(attributes, url)
    puts 'merge_blocks'
end

def get_json(segment_params, base_url)
  uri = URI(base_url + 'json/' + segment_params["key"].to_s)
  response = Net::HTTP.get(uri)
  json = JSON.parse(response)

  return json["page"]["children"]
end

def where(block, line)
    conditions = line.split()
    operator = ''
    result = false
    logic = '||'
    check = false

    conditions.each do |condition|
        if condition == '&&'
            logic = '&&'
        elsif condition == '||'
            logic = '||'
        else
            if condition.include?('<=')
                operator = '<='
                params = condition.split('<=')
                if params[0] == 'pa'
                    block_value = block[params[0]].to_i
                    value = params[1].to_i
                elsif params[0] == 'density' || params[0] == 'area'
                    block_value = block[params[0]].to_f
                    value = params[1].to_f
                else
                    block_value = block[params[0]]
                    value = params[1]
                end

                if block_value <= value
                    check = true
                else
                    check = false
                end
            elsif condition.include?('>=')
                operator = '>='
                params = condition.split('>=')
                if params[0] == 'pa'
                    block_value = block[params[0]].to_i
                    value = params[1].to_i
                elsif params[0] == 'density' || params[0] == 'area'
                    block_value = block[params[0]].to_f
                    value = params[1].to_f
                else
                    block_value = block[params[0]]
                    value = params[1]
                end

                if block_value >= value
                    check = true
                else
                    check = false
                end
            elsif condition.include?('!=')
                operator = '!='
                params = condition.split('!=')
                if params[0] == 'pa'
                    block_value = block[params[0]].to_i
                    value = params[1].to_i
                elsif params[0] == 'density' || params[0] == 'area'
                    block_value = block[params[0]].to_f
                    value = params[1].to_f
                else
                    block_value = block[params[0]]
                    value = params[1]
                end

                if block_value != value
                    check = true
                else
                    check = false
                end
            elsif condition.include?('=')
                operator = '='
                params = condition.split('=')
                if params[0] == 'pa'
                    block_value = block[params[0]].to_i
                    value = params[1].to_i
                elsif params[0] == 'density' || params[0] == 'area'
                    block_value = block[params[0]].to_f
                    value = params[1].to_f
                else
                    block_value = block[params[0]]
                    value = params[1]
                end

                if block_value = value
                    check = true
                else
                    check = false
                end
            elsif condition.include?('>')
                operator = '>'
                params = condition.split('>')
                if params[0] == 'pa'
                    block_value = block[params[0]].to_i
                    value = params[1].to_i
                elsif params[0] == 'density' || params[0] == 'area'
                    block_value = block[params[0]].to_f
                    value = params[1].to_f
                else
                    block_value = block[params[0]]
                    value = params[1]
                end

                if block_value > value
                    check = true
                else
                    check = false
                end
            elsif condition.include?('<')
                operator = '<'
                params = condition.split('<')
                if params[0] == 'pa'
                    block_value = block[params[0]].to_i
                    value = params[1].to_i
                elsif params[0] == 'density' || params[0] == 'area'
                    block_value = block[params[0]].to_f
                    value = params[1].to_f
                else
                    block_value = block[params[0]]
                    value = params[1]
                end

                if block_value < value
                    check = true
                else
                    check = false
                end
            end

            if logic == '&&'
                result = result && check
            else
                result = result || check
            end
        end
    end

    return result
end

def set_params(segment_params, line)
    params = line.split(',')

    params.each do |param|
        prm = param.split('=')
        if prm[0] == 'dc' || prm[0] == 'pa'
            segment_params[prm[0]] = prm[1].to_i
        elsif prm[0] == 'area'
            segment_params[prm[0]] = prm[1].to_f
        else
            segment_params[prm[0]] = prm[1]
        end
    end

end

base_url = 'http://bom.ciens.ucv.ve/api/'
status = 'data stored in Cache'
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

condition = ''
order_by = ''
params = ''

graph = {}
graph['bid'] = []
graph['label'] = []
graph['text'] = []
graph['images'] = []
graph['pa'] = []
graph['density'] = []
graph['area'] = []
graph['rectangle'] = []
graph['parent'] = []

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
                segment_params['url'] = url
                set_params(segment_params, params)

                if select_blocks(base_url, attributes, segment_params, status)
                    blocks = get_json(segment_params, base_url)

                    blocks.each do |block|
                        if where(block, condition)
                            attributes.each do |attribute|
                                if attribute == 'bid'
                                    graph['bid'].push(block['bid'])
                                elsif attribute == 'area'
                                    graph['area'].push(block['area'])
                                elsif attribute == 'label'
                                    graph['label'].push(block['label'])
                                elsif attribute == 'text'
                                    graph['text'].push(block['text'])
                                elsif attribute == 'images'
                                    graph['images'].push(block['images'])
                                elsif attribute == 'pa'
                                    graph['pa'].push(block['pa'])
                                elsif attribute == 'density'
                                    graph['density'].push(block['density'])
                                elsif attribute == 'rectangle'
                                    graph['rectangle'].push(block['rectangle'])
                                elsif attribute == 'parent'
                                    graph['parent'].push(block['parent'])
                                elsif attribute == '*'
                                    graph['bid'].push(block['bid'])
                                    graph['area'].push(block['area'])
                                    graph['label'].push(block['label'])
                                    graph['text'].push(block['text'])
                                    graph['images'].push(block['images'])
                                    graph['pa'].push(block['pa'])
                                    graph['density'].push(block['density'])
                                    graph['rectangle'].push(block['rectangle'])
                                    graph['parent'].push(block['parent'])
                                end
                            end
                        end
                    end

                    puts '-'
                    puts graph
                else
                    puts 'Error en segmentación'
                end
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