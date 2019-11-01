export default {
  copy: {
    success: 'Text Copied!',
    failure: 'Could not copy Text',
  },
  copyGitRevision: {
    success: 'Git Revision Copied!',
    failure: 'Could not copy Git Revision',
  },
  copyImageUrl: {
    success: 'Image URL Copied!',
    failure: 'Could not copy Image URL',
  },
  signup: {
    success: '<b>Welcome to FleetYards.net!</b> Your account has been created. <br>You will receive a confirmation email to activate your account.',
    invalid: 'Please resolve the errors before your account can be created.',
    failure: 'We could not create your account. Please try again later.',
  },
  accountConfirm: {
    success: 'Your account was successfully confirmed.<br>You can now login.',
    failure: 'Your account could not be confirmed.',
  },
  requestPasswordChange: {
    success: 'If your email address exists in our database, you will receive a password recovery link at your email address in a few minutes.',
  },
  changePassword: {
    success: 'Your password was changed successfully.',
    failure: 'Your password could not be updated.',
  },
  updateProfile: {
    success: 'Profile updated.',
  },
  avatarUpload: {
    success: 'Avatar uploaded',
  },
  vehicle: {
    add: {
      success: 'Your new <b>%{model}</b> will be delivered to your <a href="/hangar">Hangar</a>',
    },
  },
  hangarImport: {
    wrongFileType: 'Only JSON and CSV is supported.',
    wrongStructure: 'The Import needs to contain a list of ships with at least a name or model field/col.',
  },
  model: {
    onSale: '%{model} now on Sale!',
  },
  notification: {
    granted: 'Welcome to FleetYards.net Notifications!',
  },
  error: {
    usernameTaken: 'Username is already taken.',
    emailTaken: 'E-Mail is already taken.',
    accountRequired: 'You need to <a href="/sign-up/">Sign up</a> or <a href="/login/">Login</a> to add Ships to your Hangar.<br>Get more Information <a href="/hangar/preview/">here</a>',
    default: '<b>Something wrong happened.</b> <br>Have you tried turning it off and on again?',
  },
  account: {
    destroy: {
      success: "<b>Your Account has been destroyed.</b> <br>Sad to see you go :'(",
      failure: 'We could not destroy your Account! Please try again later.',
    },
  },
  confirm: {
    vehicle: {
      destroy: 'Are you sure you want to remove this Ship from you Hangar?',
    },
    hangarGroup: {
      destroy: 'Are you sure you want to remove this Group from you Hangar?',
    },
    tradeRoutes: {
      reset: 'Are you sure you want to reset all commodity prices?',
    },
    account: {
      destroy: "Are you sure you want to destroy your Account? This Action can't be reverted.",
    },
  },
}
