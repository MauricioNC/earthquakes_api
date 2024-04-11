require 'pagy/extras/headers'
require 'pagy/extras/overflow'
require 'pagy/extras/metadata'
require 'pagy/extras/items'


Pagy::DEFAULT[:items] = 20
Pagy::DEFAULT[:max_items] = 100
Pagy::DEFAULT[:page] = 1
Pagy::DEFAULT[:overflow] = :empty_page
