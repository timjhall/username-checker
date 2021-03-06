require "net/http"
require "uri"
require 'open-uri'
require 'nokogiri'

class SitesController < ApplicationController

  def index
    if params[:name]
      @name = params[:name].downcase
      if @name.match(/\s/)
        @name = ""
      end
    else
      @name = ""
    end

    # If form field is blank, don't return anything in the table (show an empty string).
    if @name == ""
      @results = { 
        GitHub: {icon: "fa-github", result: []},
        # LinkedIn: {icon: "fa-linkedin", result: []},
        Twitter: {icon: "fa-twitter", result: []},
        Instagram: {icon: "fa-instagram", result: []},
        StackExchange: {icon: "fa-stack-overflow", result: []},
        Facebook: {icon: "fa-facebook", result: []}
      }
    # If form field is not blank, validate it per each site's rules to populate each row in the table.
    else
      @results = { 
        GitHub: {icon: "fa-github", result: check_github(@name)},
        # LinkedIn: {icon: "fa-linkedin", result: check_linkedin(@name)},
        Twitter: {icon: "fa-twitter", result: check_twitter(@name)},
        Instagram: {icon: "fa-instagram", result: check_instagram(@name)},
        StackExchange: {icon: "fa-stack-overflow", result: ["Available (doesn't have to be unique)!"]},
        Facebook: {icon: "fa-facebook", result: check_facebook(@name)}
      }
    end

  end


  private
    def check_github(name)
      result = []

      # Set booleans for each rule
      too_short_or_long = (name.length <= 0 or name.length > 39) # Must be a certain length.
      bookend_hyphen = (name[0] == "-" or name[-1] == "-") # Cannot begin or end with a hyphen.

      # Github username may only contain alphanumeric characters or hyphens.
      anh_regex = /^[a-zA-Z0-9-]*$/
      if (anh_regex =~ name).is_a? Integer
        non_alphanum_or_hyphen = false
      else
        print "in the else"
        non_alphanum_or_hyphen = true
      end

      # Github username cannot have multiple consecutive hyphens.
      ch_regex = /--+/
      if (ch_regex =~ name).is_a? Integer
        consecutive_hypens = true
      else
        consecutive_hypens = false
      end

      # Print errors for violated rules:
      if too_short_or_long or bookend_hyphen or non_alphanum_or_hyphen or consecutive_hypens
        # result << "Wrong format."
        if too_short_or_long
          result << " Must be between 1 and 39 chars."
        end
        if bookend_hyphen
          result << " Cannot start or end with a hyphen."
        end
        if non_alphanum_or_hyphen
          result << " Must only contain alphanumeric characters and hyphens."
        end
        if consecutive_hypens
          result << " Cannot have consecutive hyphens."
        end
      else
        response = Net::HTTP.get_response(URI.parse("https://github.com/#{name}"))
        if ['200', '301', '302'].include? response.code
          result << "Username taken"
        else
          result << "Available!"
        end
      end

      return result
    end

    def check_linkedin(name)
      result = []
      # if name violates any of the rules, add "Wrong format..."

      # Letters or numbers
      # if anything else...
      too_short_or_long = (name.length < 5 or name.length > 30) # Must be a certain length.

      if too_short_or_long
        result << " Must be between 5 and 30 chars."
      else
        begin
          file = open("https://www.linkedin.com/in/#{name}/")
          doc = Nokogiri::HTML(file) do
            result << "Username taken"
          end
        rescue OpenURI::HTTPError => e
          if e.message == '404 Not Found'
            result << "Available!"
          else
            raise e
          end
        end
        if response.code == '200'
          result << "Username taken"
        else
          result << "Available!"
        end
      end
      return result
    end

    def check_twitter(name)
      # Letters, numbers, underscores only.
      # Max length: 15 characters

      result = []

      # Check if length is okay
      too_short_or_long = (name.length > 15) # Must be a certain length.

      # Check if alphanumeric/undercores only
      anu_regex = /^[a-zA-Z0-9_]*$/
      regex_result = anu_regex =~ name

      if (regex_result.is_a? Integer)
        non_alphanum_or_underscore = false
      else
        non_alphanum_or_underscore = true
      end

      # Create result string based on rule checks
      if too_short_or_long or non_alphanum_or_underscore
        # result << "Wrong format."
        if too_short_or_long
          result << " Must be less than 16 characters."
        end
        if non_alphanum_or_underscore
          result << " Must only contain alphanumeric characters and underscores."
        end
      else
        response = Net::HTTP.get_response(URI.parse("https://twitter.com/#{name}"))
        if ['200', '301', '302'].include? response.code
          result << "Username taken"
        else
          result << "Available!"
        end
      end
      return result
    end

    def check_instagram(name)
      # Letters, numbers, periods, underscores only
      # Max length is 30
      result = []

      # Check if length is okay
      too_short_or_long = (name.length > 30) # Must be a certain length.

      # Check if alphanumeric/undercores/periods only
      anup_regex = /^[a-zA-Z0-9_\.]*$/
      regex_result = anup_regex =~ name
      if (regex_result.is_a? Integer)
        non_alphanum_or_underscore_or_period = false
      else
        non_alphanum_or_underscore_or_period = true
      end

      # Create result string based on rule checks
      if too_short_or_long or non_alphanum_or_underscore_or_period
        # result << "Wrong format."
        if too_short_or_long
          result << " Must be less than 16 characters."
        end
        if non_alphanum_or_underscore_or_period
          result << " Must only contain alphanumeric characters, underscores, and periods."
        end
      else
        begin
          file = open("https://www.instagram.com/#{name}/")
          doc = Nokogiri::HTML(file) do
            result << "Username taken"
          end
        rescue OpenURI::HTTPError => e
          if e.message == '404 Not Found'
            result << "Available!"
          else
            raise e
          end
        end
      end
      return result
    end
  
    def check_facebook(name)

      result = []

      # Check if length is okay
      too_short_or_long = (name.length < 5 or name.length > 30) # Must be a certain length.

      # Check if alphanumeric/undercores/periods only
      anp_regex = /^[a-zA-Z0-9\.]*$/
      regex_result = anp_regex =~ name
      if (regex_result.is_a? Integer)
        non_alphanum_or_period = false
      else
        non_alphanum_or_period = true
      end

      # Check to make sure standard extensions not includedß
      extension_regex = /\.com|\.net|\.gov|\.io/
      regex_result = extension_regex =~ name
      print " fb regex_result = #{regex_result}"
      if (regex_result.is_a? Integer)
        print "setting non_extension to true"
        non_extension = true
      else
        non_extension = false
      end

      # Create result string based on rule checks
      if too_short_or_long or non_alphanum_or_period or non_extension
        # result << "Wrong format."
        if too_short_or_long
          result << " Must be between 5 and 30 characters long."
        end
        if non_alphanum_or_period
          print "HERE"

          result << " Must only contain alphanumeric characters, underscores, and periods."
        end
        if non_extension
          result << " Cannot contain common extensions like '.com', '.net', etc."
        end
      else
        response = Net::HTTP.get_response(URI.parse("https://www.facebook.com/#{name}"))
        print "FB Response = #{response.code}"
        if ['200', '301', '302'].include? response.code
          result << "Username taken"
        else
          result << "Available!"
        end
      end
      return result
    end
  
end
