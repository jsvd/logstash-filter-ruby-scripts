# validate that a password is strong
# checks basic length criteria and against a dictionary
def register(params)
  require "net/http"; require "uri"
  @dict = {}
  @dict_url = params.fetch(:url, "https://gist.githubusercontent.com/jsvd/1a5f5fb2385d8fe8473d3f84788d931c/raw/ed866df6abfba78e61e7c8cd8eb6ef12f0eef2b0/pwd.txt")
  Net::HTTP.get(URI.parse(@dict_url)).split("\n").each {|x| @dict[x.chomp] = :found }
  @minimum_length = params.fetch(:minimum_length, 8)
  @strong_length = params.fetch(:strong_length, 12)
end

def filter(event)
  reasons = []
  password = event.get("message")
  reasons.concat(test_length(password))
  reasons.concat(test_dictionary(password))
  if reasons.empty?
    (password.length >= @strong_length) ? event.tag("strong_pasword") : event.tag("good_password")
  else
    event.tag("bad_password")
    event.set("[@metadata][bad_pwd_reasons]", reasons)
  end
  [event]
end

def test_length(password)
  if password.length <= @minimum_length
    ["insufficient length: must be longer than #{@minimum_length} characters, got #{password.length}"]
  else
    []
  end
end

def test_dictionary(password)
  if @dict.key?(password)
    ["found in dictionary"]
  elsif @dict.key?(password[0...-1])
    ["variation found in dictionary"]
  elsif @dict.key?(password[1..-1])
    ["variation found in dictionary"]
  else
    []
  end
end

test "with sufficient password length" do
  parameters { { :minimum_length => 10 } }
  in_event { { "message" => "just_right" } }

  expect("it tags as 'good_password'") do |events|
    events.first.get("tags").include?("good_password")
  end
end

test "with insufficient password length" do
  parameters { { :minimum_length => 8 } }
  in_event { { "message" => "cryptic" } }

  expect("it tags as 'bad_password'") do |events|
    event = events.first
    event.get("tags").include?("bad_password")
    event.get("[@metadata][bad_pwd_reasons]").first.match(/length/)
  end
end

test "a common password" do
  parameters { { } }
  in_event { { "message" => "1234567890" } }

  expect("is tagged as 'bad_password'") do |events|
    event = events.first
    event.get("tags").include?("bad_password")
    event.get("[@metadata][bad_pwd_reasons]").first.match(/dictionary/)
  end
end

test "a variant of common password" do
  parameters { { } }
  in_event { { "message" => "1234567890!" } }

  expect("is tagged as 'bad_password'") do |events|
    event = events.first
    event.get("tags").include?("bad_password")
    event.get("[@metadata][bad_pwd_reasons]").first.match(/dictionary/)
  end
end

test "a long password length" do
  parameters { { :strong_password => 32 } }
  in_event { { "message" => "once upon a time there was a little bunny called Hopper" } }

  expect("is tagged as 'strong_password'") do |events|
    events.first.get("tags").include?("strong_password")
  end
end

