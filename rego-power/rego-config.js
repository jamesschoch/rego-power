/* REGO Power — event settings. Used by index.html (the game) and screen.html.
   Keep this file in the same folder as those pages.

   While supabaseUrl / supabaseKey are empty the game runs in DEMO MODE:
   every screen works, but scores stay on each phone and no contact details are kept or sent. */
window.REGO_CONFIG = {

  // Both values are shown in the Supabase project's API settings
  supabaseUrl: 'https://bufbdjrkfukshfjbfqhi.supabase.co',
  // the PUBLISHABLE key (sb_publishable_...). Never a secret / service_role key:
  // this file is served to every player's phone.
  supabaseKey: 'sb_publishable_Qc3FjDqWKPDQ3HVYafxwnQ_6V33pkHC',

  // One leaderboard per event code. Lower-case letters, numbers and dashes.
  // A link ending in ?event=another-code uses a separate leaderboard without editing this file.
  event: 'meug-2026',
  eventName: 'MEUG',        // shown on the screens

  // Prize wording on the contact screen. Leave '' if there is no prize:
  // the screen then reads "Stay in touch" instead of "Enter the prize draw".
  prize: 'Top score today wins.',

  // Link shown as "Privacy" under the contact form. Leave '' to show no link.
  privacyUrl: 'https://www.pattech.com/privacy-policy',

  allowSkip: true,          // show "Skip · score only" on the contact screen
  askNameCompany: true      // also ask for name and company (both optional for the player)
};
