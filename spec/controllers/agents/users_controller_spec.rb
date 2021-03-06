RSpec.describe Agents::UsersController, type: :controller do
  render_views

  let(:agent) { create(:agent) }
  let(:organisation_id) { agent.organisation_ids.first }
  let!(:user) { create(:user) }

  before do
    sign_in agent
  end

  shared_examples "with valid email" do |format|
    let(:attributes) do
      {
        first_name: "Michel",
        last_name: "Lapin",
        email: "michel@lapin.com",
        invite_on_create: "true",
      }
    end
    let(:format) { format }

    it "should send an invite" do
      subject
      expect(assigns(:user).invitation_sent_at).not_to be_nil
    end
  end

  shared_examples "with invalid params" do
    let(:attributes) { { first_name: "Michel", invite_on_create: "true" } }
    let(:format) { :html }

    it { expect { subject }.not_to change(User, :count) }
    it { expect(subject).to render_template(:new) }

    it do
      subject
      expect(assigns(:user_to_compare)).to be_nil
    end

    it "should not send an invite" do
      subject
      expect(assigns(:user).invitation_sent_at).to be_nil
    end
  end

  describe "DELETE destroy" do
    it "removes user from organisation" do
      expect do
        delete :destroy, params: { organisation_id: organisation_id, id: user.id }
        user.reload
      end.to change(user, :organisation_ids).from([organisation_id]).to([])
    end

    it "does not destroy user" do
      expect do
        delete :destroy, params: { organisation_id: organisation_id, id: user.id }
      end.not_to change(User, :count)
    end
  end

  describe "POST #create" do
    subject { post :create, params: { organisation_id: organisation_id, user: attributes } }

    context "for user without email" do
      let(:attributes) do
        {
          first_name: "Michel",
          last_name: "Lapin",
          invite_on_create: "true",
        }
      end

      it { expect { subject }.to change(User, :count).by(1) }

      it "should not send an invite" do
        subject
        expect(assigns(:user).invitation_sent_at).to be_nil
      end

      it "redirects to the created user" do
        subject
        expect(response).to redirect_to(organisation_user_path(organisation_id, User.last.id))
      end
    end

    context "for user with already existing email" do
      let!(:user) { create(:user) }

      let(:attributes) do
        {
          first_name: "Michel",
          last_name: "Lapin",
          email: user.email,
        }
      end

      it { expect { subject }.not_to change(User, :count) }
      it { expect(subject).to render_template(:compare) }

      it do
        subject
        expect(assigns(:user_to_compare)).to eq(user)
      end
    end

    it_behaves_like "with invalid params"
    it_behaves_like "with valid email", :html
  end

  describe "POST #create_from_modal" do
    subject { post :create_from_modal, params: { organisation_id: organisation_id, user: attributes }, format: format }

    context "for user without email" do
      let(:attributes) do
        {
          first_name: "Michel",
          last_name: "Lapin",
        }
      end

      let(:format) { :js }

      it { expect { subject }.to change(User, :count).by(1) }

      it "redirects to the created user" do
        subject
        expect(subject).to render_template(:create_from_modal)
      end
    end

    it_behaves_like "with invalid params"
    it_behaves_like "with valid email", :js
  end
end
