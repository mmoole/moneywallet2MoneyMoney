-- MIT License
--
-- Copyright (c) 2021 mmoole.
--
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in all
-- copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

Importer{
  version = 0.10,
  format = "CSV (MoneyWallet)",
  fileExtension = "csv",
  description = MM.localizeText("Import CSV file exported from MoneyWallet App")
}

-- needs these columns in any order in the CSV file - leave empty if n/a, can have additional columns, and , as delimiter:
-- the format that gets exported from MoneyWallet:
-- "wallet","currency","category","datetime","money","description","event","people","place","note"
-- datetime (String) (mandatory value): must be in yyyy-MM-DD hh:mm:ss in csv
-- category (String): category name - only the displayed sub-category (i.e. if you have astructure like `assets - money1 then just `money1`). If you want to create categories quickly, then export, edit and then import a csv file using the default im/exporter of MM. You can specify hierachical categories with `- `as delimiter.
-- people (String): name of the sender/payee
-- money (Number) (mandatory value): amount of transfer in numbers, decimal marker must be . (not ,)
-- currency (String): currency
-- description (String): purpose text, multiple lines can be created by using line breaks ("\n"), usually up to 140 characters
-- event (String): event field
-- place (String): place field
-- note (String): note field

-- these fields would be fine if they existed in MoneyWallet:
-- accountNumber (String): account number or IBAN of the sender/payee,
-- bankCode (String): bank code or BIC of sender/payee, usually 8 or 11 characters
-- bookingText (String): kind of booking, can be one similar to: Überweisung, Lastschrift, Dauerauftrag, Lohn/Gehalt/Rente, Dividende, Kartenzahlung V Pay // english: Credit transfer, Direct debit, standing order, Card payment, ...

-- include https://github.com/FourierTransformer/ftcsv (MIT License)
local ftcsv = require('ftcsv')

-- inspect only used for dev / debug
-- local inspect = require('inspect')
-- print(inspect(line))

local function strToDate (str)
  -- Helper function for converting localized date strings to timestamps.
  -- print("strToDate from: ", str)
  local y, m, d, H, M, S = string.match(str, "(%d%d%d%d)-(%d%d)-(%d%d) (%d%d):(%d%d):(%d%d)")
  if (d and m and y) then
    return os.time({year = y, month = m, day = d, hour = H, minute = M, seconds = S })
  else
    print("could not parse date from string: ", str)
    return nil
  end
end

function numbercomma_to_value(n)
  -- print("n is: ", n)
  local numberdot = string.gsub(n, '%,', '.')
  return numberdot
end

function ReadTransactions (account)
  print("import script CSV (MoneyWallet) importing whole file to the account, reading: ", io.filename)
  print("this script requires ftcsv.lua from https://github.com/FourierTransformer/ftcsv (MIT License)")

  -- declare the table for MM
  local transactions = {}

  -- Read transactions from a file with the delimiter as specified
  for i, line in ftcsv.parseLine(io.filename, ",") do
    -- debug / info output
    -- print("debugline: ", inspect(line))
    print("line: ", line.wallet, line.category, line.datetime, numbercomma_to_value(line.money), line.currency, line.description )
    -- wallet,currency,category,datetime,money,description,event,people,place,note

    comment_full = ''
    if line.note ~="" then
      comment_full = comment_full .. line.note
    end
    if line.event ~="" then
      comment_full = comment_full .. " Event: " .. line.event
    end
    if line.place ~="" then
      comment_full = comment_full .. " Place: " .. line.place
    end

    local transaction = {
      amount = numbercomma_to_value(line.money),
      bookingDate = strToDate(line.datetime),
      category = line.category,
      comment = comment_full,
      currency = line.currency,
      name = line.people,
      purpose = line.description
      -- bookingText = line.bookingText,
      -- accountNumber = line.accountNumber,
      -- bankCode = line.bankCode
    }
    --print("debugtransaction: ", inspect(transaction))

    table.insert(transactions, transaction)

  end

  print("import script finished.")
  return transactions

end
