require 'electron'
require 'electron/string_enhancements'

`const remote = require('electron').remote;`
`const { BrowserWindow } = require('electron')`

module Electron
  class BrowserWindow
    include Native

    def initialize(name = 'main_window', params = {}, debug: false, base: nil)
      @native = base || JS.new(`BrowserWindow`, `params.$to_n()`)
      unless base
        @native.JS[:name] = name
        @native.JS.loadURL("file://#{`__dirname`}/#{name}.html")
        @native.JS[:webContents].JS.openDevTools if debug
      end
      init_instance_methods
    end

    def self.current
      BrowserWindow.new(nil, nil, base: `remote.getCurrentWindow()`)
    end

    private

    def init_instance_methods
      methods_ruby = []
      %x{
        for(var method in #@native) {
          #{methods_ruby << `method`}
        }
      }
      methods_ruby.each do |method|
        next if method[0] == '_'
        next if method.index('send') == 0
        BrowserWindow.instance_eval do
          original = method.to_sym
          if method.index('is') == 0
            ruby_name = (underscore(method.sub('is', '')) + '?').to_sym
          elsif method.index('has') == 0
            ruby_name = (underscore(method.sub('has', '')) + '?').to_sym
          elsif method.index('set') == 0
            ruby_name = (underscore(method.sub('set', '')) + '=').to_sym
          elsif method.index('get') == 0
            ruby_name = underscore(method.sub('get', '')).to_sym
          else
            ruby_name = underscore(method).to_sym
          end
          alias_native ruby_name, original
        end
      end
    end
  end
end
