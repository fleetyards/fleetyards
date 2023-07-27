export default {
  copy: {
    success: "Testo copiato!",
    failure: "Impossibile copiare il Testo",
  },
  copyGitRevision: {
    success: "Revisione Git Copiata!",
    failure: "Impossibile copiare la revisione di Git",
  },
  copyImageUrl: {
    success: "Url Immagine Copiato!",
    failure: "Impossibile copiare l'URL dell'immagine",
  },
  copyVideoUrl: {
    success: "Url Video Copiato!",
    failure: "Impossibile copiare l'URL del Video",
  },
  copyShareUrl: {
    success: 'URL "%{url}" Copiato!',
    failure: "Impossibile copiare l'URL",
  },
  copyInviteUrl: {
    success: "L'URL \"%{url}\" d'invito Copiato!",
    failure: "Impossibile copiare l'URL dell'invito",
  },
  copyTwoFactorProvisioningUrl: {
    success: "Url Copiato!",
    failure: "Impossibile copiare l'Url",
  },
  copyBackupCodes: {
    success: "Codici Backup Copiati!",
    failure: "Impossibile copiare i codici di backup",
  },
  signup: {
    success:
      "<b>Benvenuto su FleetYards.net!</b> Il tuo account è stato creato. <br>Riceverai un'email di conferma per attivare il tuo account.",
    invalid:
      "Si prega di risolvere gli errori prima che il tuo account possa essere creato.",
    failure: "Impossibile creare un nuovo account. Riprova più tardi.",
  },
  accountConfirm: {
    success:
      "Il tuo account è stato confermato con successo.<br>Ora puoi effettuare il login.",
    failure: "Non é stato possibile confermare il tuo account.",
  },
  requestPasswordChange: {
    success:
      "Se la tua email esiste nel nostro database, entro qualche minuto riceverai un messaggio email contenente un link per il ripristino della password.",
  },
  changePassword: {
    success: "Password modificata correttamente.",
    failure: "La tua password non può essere cambiata.",
  },
  updateProfile: { success: "Profilo aggiornato." },
  updateHangar: { success: "Impostazioni Hangar aggiornate." },
  updateNotifications: { success: "Impostazioni notifiche aggiornate." },
  updateAccount: { success: "Account aggiornato." },
  avatarUpload: {
    success: "Avatar caricato",
    invalidExtension:
      "L'immagine che hai fornito ha un formato non valido. I formati supportati sono: %{extensions}.",
  },
  hangarImport: {
    success: "Importazione completata",
    partialSuccess:
      "Importazione parzialmente completata.<br><br>Navi non trovate: <br>%{missing}",
    failure: "Importazione fallita",
    invalidExtension:
      "L'import che hai fornito ha un formato non valido. I formati supportati sono: %{extensions}.",
  },
  hangarExport: {
    failure: "Esportazione fallita. Per favore riprova più tardi.",
  },
  vehicle: {
    add: {
      success:
        'La tua nuova <b>%{model}</b> sarà consegnata al tuo <a href="/hangar">Hangar</a>',
    },
    addToWishlist: {
      success:
        'Your new <b>%{model}</b> was added to your <a href="/hangar/wishlist">Wishlist</a>',
    },
    resetIngame: {
      moveToWishlist: {
        success: "Moved all Ingame bought Ships to your Wishlist.",
        failure: "Could not move all Ingame bought Ships to your Wishlist.",
      },
      removeAll: {
        success: "Removed all Ingame bought Ships from your Hangar.",
        failure: "Could not remove all Ingame bought Ships from your Hangar.",
      },
    },
  },
  model: { onSale: "%{model} è ora in vendita!" },
  notification: { granted: "Benvenuto nelle notifiche FleetYards.net!" },
  twoFactor: {
    enable: {
      success: "Autenticazione a due fattori attivata!",
      failure: "Impossibile abilitare l'autenticazione a due fattori.",
    },
    disable: {
      success: "Autenticazione a due fattori disattivata!",
      failure: "Impossibile disattivare l'autenticazione a due fattori.",
    },
    backupCodes: { failure: "Impossibile generare i codici di Backup." },
  },
  error: {
    usernameTaken: "Il nome utente è già in uso.",
    userNotFound: "Utente non trovato",
    urlInvalid: "L'URL non è valido",
    emailTaken: "Email già utilizzata.",
    fleetTaken: "Nome Flotta già in uso.",
    serialTaken: "Seriale già in uso.",
    textInvalid: "%{field} non è valido",
    hangar: {
      accountRequired:
        'You need to <a href="/sign-up/">Sign up</a> or <a href="/login/">Login</a> to add Ships to your Hangar.<br>Get more Information <a href="/hangar/preview/">here</a>',
    },
    commodityPrice: {
      accountRequired:
        'You need to <a href="/sign-up/">Sign up</a> or <a href="/login/">Login</a> to submit Prices.',
    },
    default:
      "<b>Something wrong happened.</b> <br>Have you tried turning it off and on again?",
  },
  account: {
    destroy: {
      success:
        "<b>Il tuo account è stato distrutto.</b> <br>É un peccato vederti andare :'(",
      failure: "Impossibile eliminare il tuo account. Riprova più tardi.",
    },
  },
  commodityPrice: { create: { success: "Grazie per la segnalazione." } },
  fleet: {
    create: {
      success: "La tua Flotta è stata creata.",
      failure: "Non è stato possibile salvare la Flotta.",
    },
    update: {
      success: "Impostazioni salvate.",
      failure: "Le impostazioni non possono essere salvate.",
    },
    destroy: {
      success: "La tua Flotta e' stata distrutta.",
      failure: "Non siamo riusciti a distruggere la tua Flotta.",
    },
    leave: {
      success: "Hai lasciato la Flotta.",
      failure: "Impossibile lasciare la Flotta.",
    },
    invites: {
      accept: {
        success: "Invito accettato.",
        failure: "Impossibile accettare l'invito.",
      },
      decline: {
        success: "Invito rifiutato.",
        failure: "Impossibile rifiutare l'invito.",
      },
      create: { failure: "Impossibile invitare l'utente." },
    },
    members: {
      update: {
        success: "Impostazioni salvate.",
        failure: "Le impostazioni non possono essere salvate.",
      },
      destroy: {
        success: "Membro rimosso.",
        failure: "Il membro non può essere rimosso.",
      },
      demote: {
        success: "Membro degradato.",
        failure: "Il membro non può essere degradato.",
      },
      promote: {
        success: "Membro promosso.",
        failure: "Il membro non può essere promosso.",
      },
      accept: {
        success: "Membro accettato.",
        failure: "Il membro non può essere accettato.",
      },
      decline: {
        success: "Membro respinto.",
        failure: "Il membro non può essere respinto.",
      },
    },
  },
  fleetInvite: {
    used: "<b>Richiesta di partecipazione a %{fleet} inviata!</b><br>Una volta che la tua iscrizione sarà accettata, sarai avvisato via email",
    failure: "L'invito non può essere usato.",
    notFound: "Invito non trovato.",
    confirm: 'Sei sicuro di voler partecipare alla Flotta: "%{fleet}"?',
  },
  holoViewer: {
    modelLoader: {
      failure:
        "Non è stato possibile caricare il modello 3D richiesto! Riprova più tardi.",
    },
  },
  confirm: {
    vehicle: {
      destroy: "Sei sicuro di voler rimuovere questa Nave dall'Hangar?",
    },
    hangarGroup: {
      destroy: "Sei sicuro di voler rimuovere questo Gruppo dall'Hangar?",
    },
    hangar: {
      import:
        "Le navi importate saranno aggiunte al tuo Hangar senza corrispondere alle navi già presenti.<br><br>Formati supportati sono: Fleetyards Export, Starship42 o HangarXplor.<br><br>Vuoi continuare?",
      destroySelected:
        "Sei sicuro di voler rimuovere tutte le navi selezionate dall'Hangar? Questa azione non può essere annullata.",
      destroyAll:
        "Sei sicuro di voler rimuovere tutte le navi dall'Hangar? Questa azione non può essere annullata.",
    },
    wishlist: {
      destroyAll:
        "Are you sure you want to remove all Ships from you Wishlist? This Action can't be reverted.",
    },
    tradeRoutes: {
      reset: "Are you sure you want to reset all commodity prices?",
    },
    account: {
      destroy:
        "Sei sicuro di voler eliminare il tuo account? Questa azione non potrà essere annullata.",
    },
    commodityPrice: {
      destroy:
        "Sei sicuro di voler eliminare questo prezzo? Questa azione non potrà essere annullata.",
    },
    shopCommodity: {
      destroy:
        "Are you sure you want to destroy this Commodity? This Action can't be reverted.",
    },
    fleet: {
      leave:
        "Sei sicuro di voler lasciare questa Flotta? Questa azione non potrà essere annullata.",
      destroy:
        "Sei sicuro di voler eliminare la tua Flotta? Questa azione non potrà essere annullata.",
      members: { destroy: "Sei sicuro di voler rimuovere questo membro?" },
      invites: {
        decline:
          "Sei sicuro di voler rifiutare questo invito? Questa azione non potrà essere annullata.",
      },
    },
    twoFactor: {
      generateBackupCodes:
        "Sei sicuro di voler generare nuovi Codici di Backup per la 2FA?",
    },
  },
  syncExtension: {
    started: "Syncing your Hangar...",
    success: "Your Hangar has been synced.",
    failure: "Your Hangar could not be synced.",
    notLoggedIn:
      'You need to be logged in on <a href="https://robertsspaceindustries.com" target="_blank">https://robertsspaceindustries.com</a> to sync your Hangar.',
  },
};
