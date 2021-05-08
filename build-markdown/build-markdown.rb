#!/usr/bin/env ruby
# encoding: UTF-8
# frozen_string_literal: true

=begin
  
  Script qui permet de "builder" un fichier Markdown, c'est-à-dire
  de produire le fichier HTML et le fichier PDF.

=end

require 'kramdown'

FILE_PATH   = ARGV[0]
FORMAT_PDF  = ARGV[1] == '-pdf'
FOLDER      = File.dirname(FILE_PATH)
AFFIXE      = File.basename(FILE_PATH, File.extname(FILE_PATH))

# 
# Retourne le chemin d'accès au fichier de même affixe avec 
# l'extension +ext+
# 
def file_with_ext(ext)
  File.join(FOLDER,"#{AFFIXE}.#{ext}")
end



KRAMDOWN_METHOD = FORMAT_PDF ? :to_pdf : :to_html

#
# Fichier de destination
#
DEST_PATH = file_with_ext(FORMAT_PDF ? 'pdf' : 'html')

# 
# Existe-t-il un fichier ERB de même nom ? Si oui, on le prend comme
# fichier template
# 
TEMPLATE = 
if File.exists?(file_with_ext('erb'))
  puts "Utilisation du template '#{AFFIXE}.erb'."
  file_with_ext('erb')
else
  puts "On peut créer un modèle HTML avec un fichier #{AFFIXE}.erb contenant '<%= @body %>' et '<%= @title %>'."
  'document'
end

#
# Existe-t-il un fichier style (CSS)
# 
CSS_FILE =
if File.exists?(file_with_ext('css'))
  file_with_ext('css')
elsif File.exists?(file_with_ext('sass'))
  file_with_ext('sass')
else
  puts "On peut créer un fichier #{AFFIXE}.css ou #{AFFIXE}.sass pour définir le style du document final"
  nil
end

#
# Options kramdown
# 
KRAMDOWN_OPTIONS = {
  header_offset:    0, # pour que '#' fasse un chapter
  template: TEMPLATE, # pour avoir un document entier
}


str   = File.read(FILE_PATH).force_encoding('utf-8')
code  = Kramdown::Document.new(str, KRAMDOWN_OPTIONS).send(KRAMDOWN_METHOD)
File.open(DEST_PATH,'wb'){|f|f.write(code)}