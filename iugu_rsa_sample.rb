#  para executar:
#  - Altere a linha iuru_rsa.api_token, informando seu token
#  - Execute o arquivo com o comando abaixo:
# ruby ./iugu_rsa_sample.rb
######################################################################################################
######################################################################################################
######################################################################################################

require 'openssl'
require 'base64'
require 'time'
require 'net/http'

######################################################################################################
#                                           IUGU_RSA_SAMPLE
class IUGU_RSA_SAMPLE

    attr_reader :puts_vars
    attr_writer :puts_vars

    attr_reader :api_token # Link de referência: https://dev.iugu.com/reference/autentica%C3%A7%C3%A3o#criando-chave-api-com-assinatura
    attr_writer :api_token

    attr_reader :file_private_key # Link de referência: https://dev.iugu.com/reference/autentica%C3%A7%C3%A3o#segundo-passo
    attr_writer :file_private_key

    def initialize 
        puts_vars = false
        api_token = "TOKEN CREATED ON IUGU PANEL"
        file_private_key = "/file_path/private_key.pem"
    end

    def get_request_time #Link de referência: https://dev.iugu.com/reference/autentica%C3%A7%C3%A3o#quinto-passo
        return Time.now.iso8601;
    end
    private :get_request_time

    def get_private_key
        text_key = File.read(file_private_key);
        private_key = OpenSSL::PKey::RSA.new(text_key)
        return private_key;
    end
    private :get_private_key

    def sign_body(method, endpoint, request_time, body, private_key) #Link de referência: https://dev.iugu.com/reference/autentica%C3%A7%C3%A3o#sexto-passo
        ret_sign = "";
        pattern = "#{method}|#{endpoint}\n#{api_token}|#{request_time}\n#{body}"
        signature = private_key.sign(OpenSSL::Digest::SHA256.new, pattern)
        ret_sign = Base64.strict_encode64(signature)
        return ret_sign
    end
    private :sign_body

    @last_response

    def getLastResponse
        return @last_response
    end

    @last_response_code

    def getLastResponseCode
        return @last_response_code
    end

    def send_data(method, endpoint, data, response_code_ok) # Link de referência: https://dev.iugu.com/reference/autentica%C3%A7%C3%A3o#d%C3%A9cimo-primeiro-passo
        @last_response = "";
        @last_response_code = 0;
        request_time = get_request_time()
        body = data;
        signature = sign_body(method, endpoint, request_time, body, get_private_key());

        if (puts_vars)
            puts "endpoint: #{method} - #{endpoint}";
            puts "request_time: #{request_time}";
            puts "api_token: #{api_token}";
            puts "body: #{body}";
            puts "signature: #{signature}";
        end

        uri = URI("https://api.iugu.com#{endpoint}")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = true
        request = Net::HTTP::Post.new(uri)
        request["Accept"] = 'application/json'
        request["Content-Type"] = 'application/json'
        request["Request-Time"] = request_time
        request["Signature"] = "signature=#{signature}"
        request.body = body
        
        response = http.request(request)
        @last_response_code = response.code;    
        ret = (@last_response_code == response_code_ok)
        @last_response = response.read_body     

        return ret
    end
    private :send_data

    def signature_validate(data) # Link de referência: https://dev.iugu.com/reference/validate-signature
        method = "POST"
        endpoint = "/v1/signature/validate"
        return send_data(method, endpoint, data, '200')
    end

    def transfer_requests(data)
        method = "POST"
        endpoint = "/v1/transfer_requests"
        return send_data(method, endpoint, data, '202')
    end
end

######################################################################################################

######################################################################################################
#                                    Example of use IUGU_RSA_SAMPLE
######################################################################################################
iuru_rsa = IUGU_RSA_SAMPLE.new()
iuru_rsa.api_token = ""
iuru_rsa.puts_vars = true
iuru_rsa.file_private_key = "./private.pem"

######################################################################################################
#                                         signature_validate
# Link de referência: https://dev.iugu.com/reference/validate-signature

json = "{
            \"api_token\": \"#{iuru_rsa.api_token}\",
            \"mensagem\": \"qualquer coisa\"
        }"
if (iuru_rsa.signature_validate(json)) 
    puts "Response: #{iuru_rsa.getLastResponseCode()} #{iuru_rsa.getLastResponse()}"
else
    puts "Error: #{iuru_rsa.getLastResponseCode()} #{iuru_rsa.getLastResponse()}"
end
######################################################################################################

######################################################################################################
#                                          transfer_requests
json = "{
            \"api_token\": \"#{iuru_rsa.api_token}\",
            \"transfer_type\" : \"pix\",
            \"amount_cents\" : 1,
            \"receiver\": {
                \"pix\": {
                    \"key\" : \"000000000\", 
                    \"type\" : \"cpf\"
                }
            }
        }";
if (iuru_rsa.transfer_requests(json))
    puts "Response: #{iuru_rsa.getLastResponseCode()} #{iuru_rsa.getLastResponse()}"
else
    puts "Error: #{iuru_rsa.getLastResponseCode()} #{iuru_rsa.getLastResponse()}"
end       
######################################################################################################