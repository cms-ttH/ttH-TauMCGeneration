// -*- C++ -*-
//
// Package:    ttH/TauRoast
// Class:      GenEventFilter
// 
/**\class TauRoast GenEventFilter.cc ttH/TauRoast/plugins/GenEventFilter.cc

 Description: [one line class summary]

 Implementation:
     [Notes on implementation]
*/
//
// Original Author:  Matthias Wolf
//         Created:  Thu Sep 15 05:37:55 EDT 2016
//
//


// system include files
#include <memory>

// user include files
#include "FWCore/Framework/interface/Frameworkfwd.h"
#include "FWCore/Framework/interface/EDFilter.h"

#include "FWCore/Framework/interface/Event.h"
#include "FWCore/Framework/interface/MakerMacros.h"

#include "FWCore/ParameterSet/interface/FileInPath.h"
#include "FWCore/ParameterSet/interface/ParameterSet.h"

#include "DataFormats/JetReco/interface/GenJet.h"
#include "DataFormats/JetReco/interface/GenJetCollection.h"
#include "DataFormats/PatCandidates/interface/GenericParticle.h"

#include "Math/LorentzVector.h"
#include "TMVA/Reader.h"

//
// class declaration
//

typedef ROOT::Math::LorentzVector<ROOT::Math::PxPyPzE4D<double> > LorentzVector;

class GenEventFilter : public edm::EDFilter {
   public:
      explicit GenEventFilter(const edm::ParameterSet&);
      ~GenEventFilter();

      static void fillDescriptions(edm::ConfigurationDescriptions& descriptions);

   private:
      virtual void beginJob() override;
      virtual bool filter(edm::Event&, const edm::EventSetup&) override;
      virtual void endJob() override;

      bool isFake(const reco::GenJet& j, const reco::GenParticleCollection& particles);

      // ----------member data ---------------------------
      edm::EDGetTokenT<reco::GenParticleCollection> particle_token_;
      edm::EDGetTokenT<reco::GenJetCollection> tau_token_;
      edm::EDGetTokenT<reco::GenJetCollection> jet_token_;

      std::vector<int> lepton_ids_;
      std::vector<double> lepton_pt_;
      std::vector<double> lepton_eta_;

      double jet_pt_;
      double jet_eta_;

      double tau_pt_;
      double tau_eta_;

      bool use_fakes_;
      double fake_cut_;

      unsigned int lepton_count_;
      unsigned int jet_count_;
      unsigned int tau_count_;
      unsigned int total_count_;
      unsigned int total_lepton_count_;

      float mva_pt_;
      float mva_charged_pt_;
      float mva_constituents_;
      float mva_charged_constituents_;
      float mva_signal_pt_;
      float mva_signal_constituents_;
      float mva_signal_charged_pt_;
      float mva_signal_charged_constituents_;
      float mva_iso_pt_;
      float mva_iso_constituents_;
      float mva_iso_charged_pt_;
      float mva_iso_charged_constituents_;

      std::auto_ptr<TMVA::Reader> reader_;
};

//
// constants, enums and typedefs
//

//
// static data member definitions
//

//
// constructors and destructor
//
GenEventFilter::GenEventFilter(const edm::ParameterSet& config) :
   lepton_ids_(config.getParameter<std::vector<int>>("leptonID")),
   lepton_pt_(config.getParameter<std::vector<double>>("leptonPt")),
   lepton_eta_(config.getParameter<std::vector<double>>("leptonEta")),
   jet_pt_(config.getParameter<double>("jetPt")),
   jet_eta_(config.getParameter<double>("jetEta")),
   tau_pt_(config.getParameter<double>("tauPt")),
   tau_eta_(config.getParameter<double>("tauEta")),
   use_fakes_(config.getParameter<bool>("useFakeTaus")),
   fake_cut_(config.getParameter<double>("fakeCut")),
   lepton_count_(config.getParameter<int>("minLeptons")),
   jet_count_(config.getParameter<int>("minJets")),
   tau_count_(config.getParameter<int>("minTaus")),
   total_count_(config.getParameter<int>("minTotal")),
   total_lepton_count_(config.getParameter<int>("minTotalLeptons"))
{
   particle_token_ = consumes<reco::GenParticleCollection>(config.getParameter<edm::InputTag>("genParticles"));
   tau_token_ = consumes<reco::GenJetCollection>(config.getParameter<edm::InputTag>("genTaus"));
   jet_token_ = consumes<reco::GenJetCollection>(config.getParameter<edm::InputTag>("genJets"));

   if (use_fakes_) {
      reader_.reset(new TMVA::Reader());
      reader_->AddVariable("pt", &mva_pt_);
      reader_->AddVariable("chargedPt", &mva_charged_pt_);
      reader_->AddVariable("constituents", &mva_constituents_);
      reader_->AddVariable("chargedConstituents", &mva_charged_constituents_);
      reader_->AddVariable("signalPt", &mva_signal_pt_);
      reader_->AddVariable("signalChargedPt", &mva_signal_charged_pt_);
      reader_->AddVariable("signalConstituents", &mva_signal_constituents_);
      reader_->AddVariable("signalChargedConstituents", &mva_signal_charged_constituents_);
      reader_->AddVariable("isoPt", &mva_iso_pt_);
      reader_->AddVariable("isoChargedPt", &mva_iso_charged_pt_);
      reader_->AddVariable("isoConstituents", &mva_iso_constituents_);
      reader_->AddVariable("isoChargedConstituents", &mva_iso_charged_constituents_);
      reader_->BookMVA("BDTG", edm::FileInPath("ttH/TauMCGeneration/data/faketau.weights.xml").fullPath().c_str());
   }
}


GenEventFilter::~GenEventFilter()
{
}


//
// member functions
//

template<typename T> const T*
mother(const T& p)
{
   for (unsigned int i = 0; i < p.numberOfMothers(); ++i) {
      auto mother = dynamic_cast<const T*>(p.mother(i));

      while (mother and mother->pdgId() == p.pdgId()) {
         if (mother->numberOfMothers() > 0) {
            mother = dynamic_cast<const T*>(mother->mother(0));
         } else {
            mother = 0;
            break;
         }
      }

      if (mother)
         return mother;
   }
   return 0;
}

bool
GenEventFilter::isFake(const reco::GenJet& j, const reco::GenParticleCollection& particles)
{
   mva_pt_ = j.p4().Pt();

   mva_constituents_ = j.numberOfDaughters();
   mva_charged_constituents_ = 0;
   mva_signal_constituents_ = 0;
   mva_signal_charged_constituents_ = 0;
   mva_iso_constituents_ = 0;
   mva_iso_charged_constituents_ = 0;

   LorentzVector charged_p;
   LorentzVector signal_p;
   LorentzVector signal_charged_p;
   LorentzVector iso_p;
   LorentzVector iso_charged_p;

   for (unsigned i = 0; i < j.numberOfDaughters(); ++i) {
      auto cand = j.daughterPtr(i);
      if (cand.isNonnull()) {
         auto dR = deltaR(j.p4(), cand->p4());
         if (cand->charge() != 0) {
            charged_p += cand->p4();
            ++mva_charged_constituents_;
            if (dR < .12) {
               ++mva_signal_charged_constituents_;
               signal_charged_p += cand->p4();
            } else if (dR < .3) {
               ++mva_iso_charged_constituents_;
               iso_charged_p += cand->p4();
            }
         }
         if (dR < .12) {
            ++mva_signal_constituents_;
            signal_p += cand->p4();
         } else if (dR < .3) {
            ++mva_iso_constituents_;
            iso_p += cand->p4();
         }
      }
   }

   mva_charged_pt_ = charged_p.Pt();

   mva_signal_pt_ = signal_p.Pt();
   mva_signal_charged_pt_ = signal_charged_p.Pt();
   mva_iso_pt_ = iso_p.Pt();
   mva_iso_charged_pt_ = iso_charged_p.Pt();

   const std::vector<int> allowed{11, 13};
   std::vector<std::pair<float, const reco::GenParticle*>> ps;
   for (const auto& p: particles) {
      auto dR = deltaR(j.p4(), p.p4());
      if (std::find(allowed.begin(), allowed.end(), abs(p.pdgId())) != allowed.end()
          and (p.statusFlags().isPrompt() or
               p.isPromptFinalState() or
               p.statusFlags().isDirectPromptTauDecayProduct() or
               p.isDirectPromptTauDecayProductFinalState()))
         ps.push_back(std::make_pair(dR, &p));
   }
   std::sort(std::begin(ps), std::end(ps), [](const auto& a, const auto& b) { return a.first < b.first; });

   float closest_dr = 666.;
   if (ps.size() > 0)
      closest_dr = deltaR(j.p4(), ps[0].second->p4());

   if (closest_dr < .1)
      return false;

   if (mva_pt_ < 18 or mva_signal_pt_ < 18)
      return false;

   if (fabs(j.eta() < 2.5))
      return false;

   if (mva_constituents_ > 19 or mva_charged_constituents_ > 9 or mva_iso_constituents_ > 11)
      return false;

   return reader_->EvaluateMVA("BDTG") > fake_cut_;
}

// ------------ method called on each new Event  ------------
bool
GenEventFilter::filter(edm::Event& event, const edm::EventSetup& setup)
{
   reco::GenParticleCollection leptons;
   reco::GenJetCollection taus;
   unsigned int jets = 0;

   edm::Handle<reco::GenParticleCollection> particles;
   event.getByToken(particle_token_, particles);
   edm::Handle<reco::GenJetCollection> gentaus;
   event.getByToken(jet_token_, gentaus);
   edm::Handle<reco::GenJetCollection> genjets;
   event.getByToken(jet_token_, genjets);

   for (const auto& p: *particles) {
      auto it = std::find(lepton_ids_.begin(), lepton_ids_.end(), abs(p.pdgId()));
      auto idx = std::distance(lepton_ids_.begin(), it);
      if (idx >= (int) lepton_ids_.size())
         continue;

      if (not (p.pt() > lepton_pt_[idx] and abs(p.eta()) < lepton_eta_[idx]))
         continue;

      // auto m = mother(p);
      leptons.push_back(p);
   }

   if (leptons.size() < lepton_count_)
      return false;

   for (const auto& t: *gentaus) {
      bool overlap = false;
      for (const auto& l: leptons) {
         if (deltaR(l.p4(), t.p4()) < .1) {
            overlap = true;
            break;
         }
      }

      if (not overlap and t.pt() > tau_pt_ and abs(t.eta()) < tau_eta_)
         taus.push_back(t);
   }

   if (not use_fakes_
       and (taus.size() < tau_count_ or leptons.size() + taus.size() < total_lepton_count_))
      return false;

   reco::GenJetCollection cleanjets;
   for (const auto& j: *genjets) {
      bool overlap = false;
      for (const auto& l: leptons) {
         if (deltaR(l.p4(), j.p4()) < .1) {
            overlap = true;
            break;
         }
      }

      if (not overlap)
         cleanjets.push_back(j);
   }

   if (use_fakes_)
      std::copy_if(std::begin(cleanjets), std::end(cleanjets), std::back_inserter(taus),
            [&](const auto& j) { return this->isFake(j, *particles); });

   if (taus.size() < tau_count_ or leptons.size() + taus.size() < total_lepton_count_)
      return false;

   for (const auto& j: cleanjets) {
      bool overlap = false;
      for (const auto& t: taus) {
         if (deltaR(t.p4(), j.p4()) < .1) {
            overlap = true;
            break;
         }
      }

      if (not overlap)
         ++jets;
   }

   return (
         leptons.size() + taus.size() + jets >= total_count_ and
         jets >= jet_count_
   );
}

// ------------ method called once each job just before starting event loop  ------------
void 
GenEventFilter::beginJob()
{
}

// ------------ method called once each job just after ending the event loop  ------------
void 
GenEventFilter::endJob() {
}

// ------------ method fills 'descriptions' with the allowed parameters for the module  ------------
void
GenEventFilter::fillDescriptions(edm::ConfigurationDescriptions& descriptions) {
  //The following says we do not know what parameters are allowed so do no validation
  // Please change this to state exactly what you do use, even if it is no parameters
  edm::ParameterSetDescription desc;
  desc.setUnknown();
  descriptions.addDefault(desc);
}
//define this as a plug-in
DEFINE_FWK_MODULE(GenEventFilter);
