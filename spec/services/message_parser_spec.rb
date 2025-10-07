require 'rails_helper'

RSpec.describe MessageParser, type: :service do
  describe '#stop?' do
    it 'returns true for "stop"' do
      parser = MessageParser.new('stop')
      expect(parser.stop?).to be true
    end

    it 'returns true for "STOP" (case insensitive)' do
      parser = MessageParser.new('STOP')
      expect(parser.stop?).to be true
    end

    it 'returns true for "stopall"' do
      parser = MessageParser.new('stopall')
      expect(parser.stop?).to be true
    end

    it 'returns true for "unsubscribe"' do
      parser = MessageParser.new('unsubscribe')
      expect(parser.stop?).to be true
    end

    it 'returns true for "cancel"' do
      parser = MessageParser.new('cancel')
      expect(parser.stop?).to be true
    end

    it 'returns true for "end"' do
      parser = MessageParser.new('end')
      expect(parser.stop?).to be true
    end

    it 'returns true for "quit"' do
      parser = MessageParser.new('quit')
      expect(parser.stop?).to be true
    end

    it 'returns false for partial matches' do
      parser = MessageParser.new('please stop')
      expect(parser.stop?).to be false
    end

    it 'returns false for non-stop keywords' do
      parser = MessageParser.new('hello')
      expect(parser.stop?).to be false
    end

    it 'handles whitespace by trimming' do
      parser = MessageParser.new('  stop  ')
      expect(parser.stop?).to be true
    end

    it 'returns false for empty string' do
      parser = MessageParser.new('')
      expect(parser.stop?).to be false
    end

    it 'returns false for nil' do
      parser = MessageParser.new(nil)
      expect(parser.stop?).to be false
    end
  end

  describe '#help?' do
    it 'returns true for "help"' do
      parser = MessageParser.new('help')
      expect(parser.help?).to be true
    end

    it 'returns true for "HELP" (case insensitive)' do
      parser = MessageParser.new('HELP')
      expect(parser.help?).to be true
    end

    it 'returns true for "info"' do
      parser = MessageParser.new('info')
      expect(parser.help?).to be true
    end

    it 'returns true for "INFO" (case insensitive)' do
      parser = MessageParser.new('INFO')
      expect(parser.help?).to be true
    end

    it 'returns false for partial matches' do
      parser = MessageParser.new('need help')
      expect(parser.help?).to be false
    end

    it 'returns false for non-help keywords' do
      parser = MessageParser.new('hello')
      expect(parser.help?).to be false
    end

    it 'handles whitespace by trimming' do
      parser = MessageParser.new('  help  ')
      expect(parser.help?).to be true
    end

    it 'returns false for empty string' do
      parser = MessageParser.new('')
      expect(parser.help?).to be false
    end
  end

  describe '#has_keyword?' do
    it 'returns true when message is STOP keyword' do
      parser = MessageParser.new('stop')
      expect(parser.has_keyword?).to be true
    end

    it 'returns true when message is HELP keyword' do
      parser = MessageParser.new('help')
      expect(parser.has_keyword?).to be true
    end

    it 'returns false when message has no keywords' do
      parser = MessageParser.new('hello there')
      expect(parser.has_keyword?).to be false
    end
  end

  describe '#keyword_type' do
    it 'returns :stop for STOP keywords' do
      parser = MessageParser.new('stop')
      expect(parser.keyword_type).to eq(:stop)
    end

    it 'returns :stop for unsubscribe' do
      parser = MessageParser.new('unsubscribe')
      expect(parser.keyword_type).to eq(:stop)
    end

    it 'returns :help for HELP keywords' do
      parser = MessageParser.new('help')
      expect(parser.keyword_type).to eq(:help)
    end

    it 'returns :help for info' do
      parser = MessageParser.new('info')
      expect(parser.keyword_type).to eq(:help)
    end

    it 'returns nil when no keyword detected' do
      parser = MessageParser.new('hello')
      expect(parser.keyword_type).to be_nil
    end

    it 'prioritizes STOP over HELP' do
      # In the implementation, stop? is checked first
      parser = MessageParser.new('stop')
      expect(parser.keyword_type).to eq(:stop)
    end
  end

  describe 'case insensitivity' do
    it 'detects mixed case STOP keywords' do
      %w[Stop StOp STOP sToP].each do |keyword|
        parser = MessageParser.new(keyword)
        expect(parser.stop?).to be(true), "Expected '#{keyword}' to be detected as STOP"
      end
    end

    it 'detects mixed case HELP keywords' do
      %w[Help HeLp HELP hElP].each do |keyword|
        parser = MessageParser.new(keyword)
        expect(parser.help?).to be(true), "Expected '#{keyword}' to be detected as HELP"
      end
    end
  end
end
