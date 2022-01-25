# frozen_string_literal: true

require_relative 'hangman_ascii'

class Display
  include HangmanASCII
end

puts Display::HANGMAN_PICS
