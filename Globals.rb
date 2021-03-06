###############################
##Alumnos:                   ##
##Jesus Cibeira. 24.203.933  ##
##Johan Quintero. 22.668.628 ##
###############################

require 'uri'
require 'json'
require 'net/http'

$BASE_URL = 'http://bom.ciens.ucv.ve/api/'
$STATUS = 'data stored in Cache'
$KEY = '94'

$VALID_ATTRIBUTES = ['*', 'bid', 'label', 'text', 'images', 'pa', 'density', 'area', 'rectangle', 'parent']
$VALID_PARAMS = ['url', 'key', 'categories', 'area', 'pa', 'dc', 'method', 'granmethod', 'align']


def get_request(function, params)
    url = URI.parse($BASE_URL + function)
    req = Net::HTTP::Get.new(url.to_s)
    req.set_form_data(params)
    req = Net::HTTP::Get.new(url.path + '?' + req.body)
    res = Net::HTTP.start(url.host, url.port) {
        |http| http.request(req)
    }
    return res.body
end

def bom_open()
    response = JSON.parse(get_request('open', {}))
    return response['key']
end

def bom_segment(params)
    response = JSON.parse(get_request('segment', params))
    return response.include?(status)
end

def bom_json(key)
    uri = 'json/' + key.to_s
    response = JSON.parse(get_request(uri, {}))
    return response["page"]["children"]
end

def file_json()
    file_name = "file.json"
    line = ""
    
    File.open(file_name) do |file|
        line = file.gets
    end

    json = JSON.parse(line)
    return json["page"]["children"]
end

def verify_attr(value)
    if value.is_a?(Hash)
        value = value.to_s
        if  value.length > 15
            return value.scan(/.{15}|.+/).join("\n")
        else
            return value
        end
    end

    if value.is_a?(String) && value.length > 30
        return value.scan(/.{30}|.+/).join("\n")
    else
        return value
    end
end

def convert_type(attrs, bvalue)
    if attrs[0] == 'pa'
        block_value = bvalue.to_i
        value = attrs[1].to_i
    elsif attrs[0] == 'density' || attrs[0] == 'area'
        block_value = bvalue.to_f
        value = attrs[1].to_f
    else
        block_value = bvalue
        value = attrs[1]
    end
    return block_value, value
end