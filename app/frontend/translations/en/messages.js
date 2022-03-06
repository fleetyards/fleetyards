export default {
  account: {
    destroy: {
      failure: 'We could not destroy your Account! Please try again later.',
      success:
        "<b>Your Account has been destroyed.</b> <br>Sad to see you go :'(",
    },
  },
  accountConfirm: {
    failure: 'Your account could not be confirmed.',
    success: 'Your account was successfully confirmed.<br>You can now login.',
  },
  avatarUpload: {
    invalidExtension:
      'The Picture you provided has an invalid Format. Supported Formats are: %{extensions}.',
    success: 'Avatar uploaded',
  },
  changePassword: {
    failure: 'Your password could not be updated.',
    success: 'Your password was changed successfully.',
  },
  commodityPrice: {
    create: {
      success: 'Thank you for your price submission.',
    },
  },
  confirm: {
    account: {
      destroy:
        "Are you sure you want to destroy your Account? This Action can't be reverted.",
    },
    commodityPrice: {
      destroy:
        "Are you sure you want to destroy this Price? This Action can't be reverted.",
    },
    fleet: {
      destroy:
        "Are you sure you want to destroy your Fleet? This Action can't be reverted.",
      invites: {
        decline:
          "Are you sure you want to decline this Invite? This Action can't be reverted.",
      },
      leave:
        "Are you sure you want to leave the Fleet? This Action can't be reverted.",
      members: {
        destroy: 'Are you sure you want to remove this Member?',
      },
    },
    hangar: {
      destroyAll:
        "Are you sure you want to remove all Ships from you Hangar? This Action can't be reverted.",
      destroySelected:
        "Are you sure you want to remove all Selected Ships from you Hangar? This Action can't be reverted.",
      import:
        'Imported ships will be added to your Hangar without matching to exisiting Ships.<br><br>Supported Formats are: Fleetyards Export, Starship42 or HangarXplor.<br><br>Do you want to continue?',
    },
    hangarGroup: {
      destroy: 'Are you sure you want to remove this Group from you Hangar?',
    },
    modal: {
      dirty: 'You have unsaved changes that will be lost.',
    },
    shopCommodity: {
      destroy:
        "Are you sure you want to destroy this Commodity? This Action can't be reverted.",
    },
    tradeRoutes: {
      reset: 'Are you sure you want to reset all commodity prices?',
    },
    twoFactor: {
      generateBackupCodes:
        'Are you sure you want to regenerate your Two-factor Backup Codes?',
    },
    vehicle: {
      destroy: 'Are you sure you want to remove this Ship from you Hangar?',
    },
  },
  copy: {
    failure: 'Could not copy Text',
    success: 'Text Copied!',
  },
  copyBackupCodes: {
    failure: 'Could not copy Backup Codes',
    success: 'Backup Codes Copied!',
  },
  copyGitRevision: {
    failure: 'Could not copy Git Revision',
    success: 'Git Revision Copied!',
  },
  copyImageUrl: {
    failure: 'Could not copy Image URL',
    success: 'Image URL Copied!',
  },
  copyInviteUrl: {
    failure: 'Could not copy Invite URL',
    success: 'Invite URL "%{url}" Copied!',
  },
  copyShareUrl: {
    failure: 'Could not copy URL',
    success: 'URL "%{url}" Copied!',
  },
  copyVideoUrl: {
    failure: 'Could not copy Video URL',
    success: 'Video URL Copied!',
  },
  error: {
    commodityPrice: {
      accountRequired:
        'You need to <a href="/sign-up/">Sign up</a> or <a href="/login/">Login</a> to submit Prices.',
    },
    default:
      '<b>Something wrong happened.</b> <br>Have you tried turning it off and on again?',
    emailTaken: 'Email is already taken.',
    fleetTaken: 'Fleet is already taken.',
    hangar: {
      accountRequired:
        'You need to <a href="/sign-up/">Sign up</a> or <a href="/login/">Login</a> to add Ships to your Hangar.<br>Get more Information <a href="/hangar/preview/">here</a>',
    },
    serialTaken: 'Serial is already taken.',
    textInvalid: '%{field} is invalid',
    urlInvalid: 'URL is invalid',
    usernameTaken: 'Username is already taken.',
    userNotFound: 'User not found',
  },
  fleet: {
    create: {
      failure: 'Fleet could not be saved.',
      success: 'Your Fleet has been created.',
    },
    destroy: {
      failure: 'We could not destroy your Fleet.',
      success: 'Your Fleet has been destroyed.',
    },
    invites: {
      accept: {
        failure: 'Could not accept Invite.',
        success: 'Invite accepted.',
      },
      create: {
        failure: 'Could not invite User.',
      },
      decline: {
        failure: 'Could not decline Invite.',
        success: 'Invite declined.',
      },
    },
    leave: {
      failure: 'Could not leave the Fleet.',
      success: 'You have left the Fleet.',
    },
    members: {
      accept: {
        failure: 'Member could not be accepted.',
        success: 'Member accepted.',
      },
      decline: {
        failure: 'Member could not be declined.',
        success: 'Member declined.',
      },
      demote: {
        failure: 'Member could not be demoted.',
        success: 'Member demoted.',
      },
      destroy: {
        failure: 'Member could not be removed.',
        success: 'Member removed.',
      },
      promote: {
        failure: 'Member could not be promoted.',
        success: 'Member promoted.',
      },
      update: {
        failure: 'Settings could not be saved.',
        success: 'Settings saved.',
      },
    },
    update: {
      failure: 'Settings could not be saved.',
      success: 'Settings saved.',
    },
  },
  fleetInvite: {
    confirm: 'Are you sure you want to join the Fleet: "%{fleet}"?',
    failure: 'Invite could not be used.',
    notFound: 'Invite not found.',
    used: '<b>Join request for %{fleet} send!</b><br>Once your Membership is accepted you will be notified via email',
  },
  hangarExport: {
    failure: 'Export failed, Please try again later.',
  },
  hangarImport: {
    failure: 'Import failed',
    invalidExtension:
      'The Import you provided has an invalid Format. Supported Formats are: %{extensions}.',
    partialSuccess:
      'Import partially completed.<br><br>Not found Ships: <br>%{missing}',
    success: 'Import completed',
  },
  holoViewer: {
    modelLoader: {
      failure:
        'We could not load the requested 3D model! Please try again later.',
    },
  },
  model: {
    onSale: '%{model} now on Sale!',
  },
  notification: {
    granted: 'Welcome to FleetYards.net Notifications!',
  },
  requestPasswordChange: {
    success:
      'If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes.',
  },
  signup: {
    failure: 'We could not create your account. Please try again later.',
    invalid: 'Please resolve the errors before your account can be created.',
    success:
      '<b>Welcome to FleetYards.net!</b> Your account has been created. <br>You will receive a confirmation email to activate your account.',
  },
  twoFactor: {
    backupCodes: {
      failure: 'Backup Codes could not be generated.',
    },
    disable: {
      failure: 'Could not diable Two-factor Authentication.',
      success: 'Two-factor Authentication disabled!',
    },
    enable: {
      failure: 'Could not enable Two-factor Authentication.',
      success: 'Two-factor Authentication enabled!',
    },
  },
  updateAccount: {
    success: 'Account updated.',
  },
  updateHangar: {
    success: 'Hangar Settings updated.',
  },
  updateNotifications: {
    success: 'Notification Settings updated.',
  },
  updateProfile: {
    success: 'Profile updated.',
  },
  vehicle: {
    add: {
      success:
        'Your new <b>%{model}</b> will be delivered to your <a href="/hangar">Hangar</a>',
    },
  },
}
