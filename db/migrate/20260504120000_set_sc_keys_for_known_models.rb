class SetScKeysForKnownModels < ActiveRecord::Migration[7.1]
  MAPPING = {
    "orig-890-jump" => "orig_890jump",
    "orig-600i-explorer" => "orig_600i",
    "crus-a1-spirit" => "crus_spirit_a1",
    "crus-c1-spirit" => "crus_spirit_c1",
    "crus-a2-hercules" => "crus_starlifter_a2",
    "crus-c2-hercules" => "crus_starlifter_c2",
    "crus-m2-hercules" => "crus_starlifter_m2",
    "rsi-aurora-mk-i-cl" => "rsi_aurora_gs_cl",
    "rsi-aurora-mk-i-es" => "rsi_aurora_gs_es",
    "rsi-aurora-mk-i-ln" => "rsi_aurora_gs_ln",
    "rsi-aurora-mk-i-lx" => "rsi_aurora_gs_lx",
    "rsi-aurora-mk-i-mr" => "rsi_aurora_gs_mr",
    "rsi-aurora-mk-i-se" => "rsi_aurora_gs_se",
    "rsi-zeus-mk-ii-cl" => "rsi_zeus_cl",
    "rsi-zeus-mk-ii-es" => "rsi_zeus_es",
    "aegs-vanguard-warden" => "aegs_vanguard",
    "aegs-gladius-pirate-edition" => "aegs_gladius_pir",
    "misc-reliant-kore" => "misc_reliant",
    "rsi-ursa" => "rsi_ursa_rover",
    "rsi-ursa-fortuna" => "rsi_ursa_rover_emerald",
    "krig-l-21-wolf" => "krig_l21_wolf",
    "krig-l-22-alpha-wolf" => "krig_l22_alphawolf",
    "krig-p-52-merlin" => "krig_p52_merlin",
    "krig-p-72-archimedes" => "krig_p72_archimedes",
    "xnaa-san-tok-yai" => "xnaa_santokyai",
    "drak-dragonfly-black" => "drak_dragonfly",
    "drak-dragonfly-yellowjacket" => "drak_dragonfly_yellow",
    "drak-dragonfly-star-kitten-edition" => "drak_dragonfly_pink",
    "argo-csv-sm" => "argo_csv_cargo",
    "argo-mpuv-cargo" => "argo_mpuv",
    "argo-mpuv-personnel" => "argo_mpuv_transport",
    "argo-mpuv-tractor" => "argo_mpuv_1t",
    "crus-mercury-star-runner" => "crus_star_runner",
    "crus-ares-inferno" => "crus_starfighter_inferno",
    "crus-ares-ion" => "crus_starfighter_ion",
    "espr-blade" => "vncl_blade",
    "espr-glaive" => "vncl_glaive",
    "espr-stinger" => "vncl_stinger",
    "mrai-razor" => "misc_razor",
    "mrai-razor-ex" => "misc_razor_ex",
    "mrai-razor-lx" => "misc_razor_lx",
    "xnaa-khartu-al" => "xian_scout",
    "xnaa-nox" => "xian_nox",
    "xnaa-nox-kue" => "xian_nox_kue",
    "grey-shiv" => "glsn_shiv",
    "anvl-f8c-lightning" => "anvl_lightning_f8c",
    "anvl-f8c-lightning-executive-edition" => "anvl_lightning_f8c_exec"
  }.freeze

  def up
    MAPPING.each do |slug, sc_key|
      execute ActiveRecord::Base.sanitize_sql_array(
        ["UPDATE models SET sc_key = ? WHERE slug = ?", sc_key, slug]
      )
    end
  end

  def down
    MAPPING.each_key do |slug|
      execute ActiveRecord::Base.sanitize_sql_array(
        ["UPDATE models SET sc_key = NULL WHERE slug = ?", slug]
      )
    end
  end
end
