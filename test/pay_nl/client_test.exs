defmodule PayNL.ClientTest do
  use ExUnit.Case, async: false
  use ExVCR.Mock

  setup_all do
    ExVCR.Config.cassette_library_dir("test/vcr_cassettes")
    :ok
  end

  doctest PayNL

  @invalid_params [
    remote_ip: "127.0.0.1",
    amount_in_cents: 100,
    return_url: "https://example.com/return",
    notification_url: "https://example.com/notify",
    service_id: "123",
    api_token: "abc",
    test: true
  ]

  @valid_params [
    remote_ip: "127.0.0.1",
    amount_in_cents: 100,
    return_url: "https://example.com/return",
    notification_url: "https://example.com/notify",
    test: true
  ]

  test "start transaction with invalid credentials" do
    {:ok, options} = PayNL.TransactionOptions.create(@invalid_params)
    use_cassette "invalid_credentials" do
      assert {:error, :invalid_api_token_or_service_id} = PayNL.Client.start_transaction(options)
    end
  end

  test "start transaction with valid credentials" do
    {:ok, options} = PayNL.TransactionOptions.create(@valid_params)
    use_cassette "valid_credentials" do
      assert {
               :ok,
               %{
                 "endUser" => %{
                   "blacklist" => "0"
                 },
                 "request" => %{
                   "errorId" => "",
                   "errorMessage" => "",
                   "result" => "1"
                 },
                 "transaction" => %{
                   "paymentReference" => "6000 0010 4364 5302",
                   "paymentURL" =>
                     "https://api.pay.nl/controllers/payments/issuer.php?orderId=1043645302Xc611c&entranceCode=1c4af3fb2d8d7b5c7e7651d6262562a8e13c978a&profileID=613&lang=NL",
                   "popupAllowed" => "0",
                   "transactionId" => "1043645302Xc611c"
                 }
               }
             } = PayNL.Client.start_transaction(options)
    end
  end



  test "should return a list of payment options" do
    use_cassette "get_payment_options_success" do
      {:ok, credentials} = PayNL.TransactionOptions.credentials(@valid_params)
      {:ok, payment_options} = PayNL.Client.get_payment_options(credentials)
      assert %PayNL.PaymentOptions.Profile{
               active: false,
               costs_fixed: 0,
               costs_percentage: 0,
               countries: ["NL"],
               id: 10,
               image_url: "https://admin.pay.nl/images/payment_profiles/10.gif",
               name: "iDEAL",
               payment_method_id: 4,
               visible_name: "iDEAL",
               options: [
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "1",
                   image_url: "https://admin.pay.nl/images/payment_banks/1.png",
                   name: "ABN Amro",
                   visible_name: "ABN Amro"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "10",
                   image_url: "https://admin.pay.nl/images/payment_banks/10.png",
                   name: "Triodos Bank",
                   visible_name: "Triodos Bank"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "11",
                   image_url: "https://admin.pay.nl/images/payment_banks/11.png",
                   name: "Van Lanschot",
                   visible_name: "Van Lanschot"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "12",
                   image_url: "https://admin.pay.nl/images/payment_banks/12.png",
                   name: "Knab",
                   visible_name: "Knab"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "2",
                   image_url: "https://admin.pay.nl/images/payment_banks/2.png",
                   name: "Rabobank",
                   visible_name: "Rabobank"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "4",
                   image_url: "https://admin.pay.nl/images/payment_banks/4.png",
                   name: "ING",
                   visible_name: "ING"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "5",
                   image_url: "https://admin.pay.nl/images/payment_banks/5.png",
                   name: "SNS",
                   visible_name: "SNS"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "5080",
                   image_url: "https://admin.pay.nl/images/payment_banks/5080.png",
                   name: "bunq",
                   visible_name: "bunq"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "5081",
                   image_url: "https://admin.pay.nl/images/payment_banks/5081.png",
                   name: "Moneyou",
                   visible_name: "Moneyou"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "5082",
                   image_url: "https://admin.pay.nl/images/payment_banks/5082.png",
                   name: "Svenska Handelsbanken",
                   visible_name: "Svenska Handelsbanken"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "8",
                   image_url: "https://admin.pay.nl/images/payment_banks/8.png",
                   name: "ASN Bank",
                   visible_name: "ASN Bank"
                 },
                 %PayNL.PaymentOptions.Profile.Option{
                   active: true,
                   id: "9",
                   image_url: "https://admin.pay.nl/images/payment_banks/9.png",
                   name: "RegioBank",
                   visible_name: "RegioBank"
                 }
               ]
             } == List.first(payment_options)
    end
  end

  test "should return a list of banks" do
    use_cassette "get_banks_success" do
      {:ok, banks} = PayNL.Client.get_banks()
      assert %PayNL.Bank{
               available: true,
               id: 1,
               image: "https://www.pay.nl/betalen/images/tas2iDealBankAbnAmro.png",
               issuer_id: 31,
               name: "ABN Amro",
               swift: "ABNANL2A"
             } = List.first(banks)
    end
  end

  test "should return transaction details" do
    use_cassette "get_transaction_details" do
      {:ok, credentials} = PayNL.TransactionOptions.credentials(@valid_params)
      {:ok, %{"paymentDetails" => _}} = PayNL.Client.get_transaction_details(credentials, "1043645302Xc611c")
    end
  end

  test "it can resolve a capture status message" do
    assert {:ok, :pending} == PayNL.Client.extract_payment_status_from_capture_details({:ok,
      %{
        "request" => %{"errorId" => "", "errorMessage" => "", "result" => "1"},
        "result" => %{
          "directDebit" => [
            %{
              "amount" => "100",
              "bankaccountBic" => "ABNANL2A",
              "bankaccountHolder" => "G.j. de Brieder",
              "bankaccountNumber" => "NL24ABNA0601324080",
              "declineCode" => "0",
              "declineDate" => "",
              "declineName" => "",
              "description" => "Test capture",
              "paymentSessionId" => "1042263076",
              "receiveDate" => "",
              "referenceId" => "IL-9624-0459-3600",
              "sendDate" => "",
              "statusCode" => "91",
              "statusName" => "Toegevoegd"
            }
          ],
          "mandate" => %{
            "amount" => "100",
            "bankaccounOwner" => "G.j. de Brieder",
            "bankaccountBic" => "ABNANL2A",
            "bankaccountNumber" => "NL24ABNA0601324080",
            "description" => "Test capture",
            "email" => "",
            "extra1" => "",
            "extra2" => "",
            "info" => "",
            "intervalPeriod" => "0",
            "intervalQuantity" => "1",
            "intervalValue" => "0",
            "ipAddress" => "185.47.134.204",
            "mandateId" => "IO-3524-0278-6680",
            "object" => "",
            "state" => "single",
            "type" => "single"
          }
        }
      }})

  end
end
