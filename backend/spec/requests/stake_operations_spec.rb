# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Stake Operations API", type: :request do
  let!(:org) { Organization.create!(name: "Test Org") }
  let!(:key) { ApiKey.create!(organization: org, token: "test-key") }
  let!(:other_org) { Organization.create!(name: "Other Org") }
  let!(:eth) { network!(:ethereum) }
  let!(:sol) { network!(:solana) }
  let!(:sol_validator) { Validator.create!(organization: org, network: sol, external_ref: "Stake111", balance: "1000") }

  def create_operation(params, headers: auth_headers)
    post "/api/v1/stake_operations", params: params.to_json, headers: headers
  end

  describe "POST /api/v1/stake_operations" do
    let(:valid_params) { { network: "ethereum", action: "stake", amount: "1000000000" } }

    it "creates the operation, submits it through the chain client and returns 201" do
      create_operation(valid_params)

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]).to include(
        "status" => "submitted", "amount" => "1000000000", "network" => "ethereum", "action" => "stake",
        "external_id" => start_with("mock-stake-")
      )
    end

    it "schedules confirmation polling for the submitted operation" do
      expect { create_operation(valid_params) }.to have_enqueued_job(StakeConfirmationJob)
    end

    it "creates an unstake operation within the staked balance" do
      create_operation({ network: "solana", action: "unstake", amount: "500" })
      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "action")).to eq("unstake")
    end

    it "rejects an unstake larger than the staked balance" do
      create_operation({ network: "solana", action: "unstake", amount: "1001" })

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "details")).to include("Amount exceeds staked balance of 1000")
    end

    it "marks the operation failed when the chain rejects the submission" do
      allow_any_instance_of(ChainClients::MockChainClient).to receive(:submit_stake).and_raise(ChainClients::Error, "insufficient funds")

      expect { create_operation(valid_params) }.not_to have_enqueued_job(StakeConfirmationJob)
      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"]).to include("status" => "failed", "error_message" => "insufficient funds")
    end

    {
      "unknown network" => [ { network: "cardano", action: "stake", amount: "1000" }, "unknown_network" ],
      "missing network" => [ { action: "stake", amount: "1000" }, "unknown_network" ],
      "invalid action" => [ { network: "ethereum", action: "swap", amount: "1000" }, "validation_failed" ],
      "zero amount" => [ { network: "ethereum", action: "stake", amount: "0" }, "validation_failed" ],
      "negative amount" => [ { network: "ethereum", action: "stake", amount: "-100" }, "validation_failed" ],
      "decimal amount" => [ { network: "ethereum", action: "stake", amount: "10.5" }, "validation_failed" ],
      "float JSON amount" => [ { network: "ethereum", action: "stake", amount: 10.5 }, "validation_failed" ],
      "missing amount" => [ { network: "ethereum", action: "stake" }, "validation_failed" ]
    }.each do |description, (params, code)|
      it "rejects #{description} with 422 and does not persist anything" do
        expect { create_operation(params) }.not_to change(StakeOperation, :count)
        expect(response).to have_http_status(:unprocessable_entity)
        expect(error_code).to eq(code)
      end
    end

    it "rejects malformed JSON with 400" do
      post "/api/v1/stake_operations", params: "{not json", headers: auth_headers
      expect(response).to have_http_status(:bad_request)
      expect(error_code).to eq("bad_request")
    end

    it "rejects unauthorized requests" do
      create_operation(valid_params, headers: { "Content-Type" => "application/json" })
      expect(response).to have_http_status(:unauthorized)
    end

    describe "Idempotency-Key" do
      let(:headers) { auth_headers.merge("Idempotency-Key" => "client-uuid-1") }

      it "returns the original operation on retry instead of submitting twice" do
        create_operation(valid_params, headers: headers)
        original = response.parsed_body["data"]

        expect(ChainClients::MockChainClient).not_to receive(:new)
        expect { create_operation(valid_params, headers: headers) }.not_to change(StakeOperation, :count)

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["data"]).to eq(original)
      end

      it "returns 409 when the key is reused with a different payload" do
        create_operation(valid_params, headers: headers)
        create_operation(valid_params.merge(amount: "5"), headers: headers)

        expect(response).to have_http_status(:conflict)
        expect(error_code).to eq("idempotency_conflict")
      end

      it "scopes keys per organization" do
        ApiKey.create!(organization: other_org, token: "other-key")
        create_operation(valid_params, headers: headers)
        create_operation(valid_params, headers: auth_headers("other-key").merge("Idempotency-Key" => "client-uuid-1"))

        expect(response).to have_http_status(:created)
      end
    end
  end

  describe "GET /api/v1/stake_operations" do
    before do
      org.stake_operations.create!(network: eth, action: "stake", amount: "5000", status: "submitted", external_id: "mock-1", created_at: 1.minute.ago)
      org.stake_operations.create!(network: sol, action: "unstake", amount: "200", status: "pending")
      other_org.stake_operations.create!(network: eth, action: "stake", amount: "999", status: "pending")
    end

    it "lists only the authenticated org's operations, newest first" do
      get "/api/v1/stake_operations", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].map { _1["amount"] }).to eq(%w[ 200 5000 ])
    end
  end

  describe "GET /api/v1/stake_operations/:id" do
    it "returns the operation" do
      operation = org.stake_operations.create!(network: eth, action: "stake", amount: "5")
      get "/api/v1/stake_operations/#{operation.id}", headers: auth_headers

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(operation.id)
    end

    it "returns 404 for another organization's operation" do
      foreign = other_org.stake_operations.create!(network: eth, action: "stake", amount: "5")
      get "/api/v1/stake_operations/#{foreign.id}", headers: auth_headers

      expect(response).to have_http_status(:not_found)
      expect(error_code).to eq("not_found")
    end
  end
end
