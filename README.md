### Scripts for the Logstash Ruby Filter

Since version 3.1.0 the logstash ruby filter allows you to use a path to load custom ruby code instead of inlining it the logstash config itself.

This repo is a place to store scripts so others can download and use them

To use a script, download the .rb file and point to in your logstash config. For example:

```
input { # ... }
filter {
  ruby {
    path => "./pwd_checker.rb"
    script_params => {
      "minimum_length" => 8
      "strong_length" => 32
    }
  }
}
output { # ... }
```
