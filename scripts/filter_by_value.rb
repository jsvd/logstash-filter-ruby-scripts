# input { 
#   stdin { codec => json  }
# }
# filter { 
#   ruby {
#     path => '/tmp/path/filter_by_value.rb' 
#     script_params => { 
#       'field' => 'location.location'
#       'value' => 4
#       'target' => 'data'
#       'key' => 'number'
#     }
#   }
# }

def register(params)
  @field = params["field"]
  @key = params["key"]
  @value = params["value"]
  @target = params["target"]
end

def filter(event)
  filter_value = event.get(@field)
  filtered = filter_value.select {|v| v[@key] == @value }
  event.set(@target, filtered)
  [event]
end

test "selects objects from field if key matches value" do
  parameters do
    {
      "field" => "location.location",
      "key" => "number",
      "value" => 4,
      "target" => "data"
    }
  end

  in_event { {
    "location.location": [
      { "name": "some_name", "category": "A", "other_fields": "...", "number": 3 },
      { "name": "some_name", "category": "C", "other_fields": "...", "number": 4 },
      { "name": "some_name", "category": "D", "other_fields": "...", "number": 4 }
    ]
  } }

  expect("target field has 2 objects") do |events|
    events.first.get("data").size == 2
  end
  expect("target field only has objects with number 4") do |events|
    events.first.get("data").all? {|h| h['number'] == 4 }
  end
end
