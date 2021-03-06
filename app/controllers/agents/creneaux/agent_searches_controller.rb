class Agents::Creneaux::AgentSearchesController < AgentAuthController
  respond_to :html, :js

  def index
    skip_policy_scope
    respond_to do |format|
      format.html do
        @organisation = current_organisation
        @motifs = @organisation.motifs.active
        @agents = @organisation.agents.complete.active
        @lieux = @organisation.lieux
      end
      format.js do
        @agent_search = Creneau::AgentSearch.new(filter_params)
        @agent_search.organisation_id = current_organisation.id
        set_params
        @lieux = @agent_search.lieux

        @creneaux_by_lieux = @lieux.each_with_object({}) do |lieu, creneaux_by_lieux|
          creneaux_by_lieux[lieu.id] = Creneau.for_motif_and_lieu_from_date_range(@motif.name, lieu, @date_range, true, @agent_ids)
        end
      end
    end
  end

  def by_lieu
    skip_authorization

    @agent_search = Creneau::AgentSearch.new(by_lieu_params)
    @agent_search.organisation_id = current_organisation.id
    set_params
    @lieu = @agent_search.lieu

    @creneaux = Creneau.for_motif_and_lieu_from_date_range(@motif.name, @lieu, @date_range, true, @agent_ids)
  end

  def set_params
    @date_range = @agent_search.from_date..(@agent_search.from_date + 6.days)
    @motif = @agent_search.motif
    @agent_ids = @agent_search.agent_ids
  end

  private

  def filter_params
    params.require(:creneau_agent_search).permit(:motif_id, :from_date, agent_ids: [], lieu_ids: [])
  end

  def by_lieu_params
    params.permit(:lieu_id, :motif_id, :from_date, agent_ids: [])
  end
end
