fs = require 'fs'
csvparse = require 'csv-parse'
_ = require 'lodash'
geocoder = require 'geocoder'
async = require 'async'

filename = process.argv[2]
fs.readFile filename, 'utf8', (err, data) ->
  if err then throw err
  csvparse data, {}, (err, output) ->

    columns = output[0]
    loc1idx = _.findIndex columns, (col) -> col == 'loc1'

    async.mapSeries output.slice(1)
    , (row, nextcb) ->
      address = row[loc1idx] + ", San Francisco, CA"
      console.log "Looking up #{address}"
      geocoder.geocode address, (err, data) ->
        if err then return nextcb err, null
        if data.results.length == 1
          latlng = data.results[0].geometry.location
          # Execute next query after some ms, to not exceed api limit
          setTimeout (-> nextcb null, latlng), 500
        else
          # abort
          nexterr = "Unexpected result count #{data.results.length}! Logging json and aborting."
          nextcb nexterr
          console.log nexterr
          console.log JSON.stringify data
    , (err, results) ->
      if err then console.error err
      formattedResults = _.map results, (ll) -> if ll then "#{ll.lat},#{ll.lng}" else null
      console.log formattedResults.join('\n')

