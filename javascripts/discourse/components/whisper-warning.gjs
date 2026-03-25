import Component from "@glimmer/component";
import { action } from "@ember/object";
import { service } from "@ember/service";
import DButton from "discourse/components/d-button";
import concatClass from "discourse/helpers/concat-class";
import { i18n } from "discourse-i18n";

export default class WhisperWarning extends Component {
  @service currentUser;
  @service composer;

  get showWarning() {
    const canWhisper = this.composer.showWhisperToggle;
    const isNotNewTopic =
      this.args.outletArgs.model.get("action") !== "createTopic";
    const isNotNewPM =
      this.args.outletArgs.model.get("action") !== "privateMessage";
    const isNotSharedDraft =
      this.args.outletArgs.model.get("action") !== "createSharedDraft";

    if (!canWhisper || !isNotNewTopic || !isNotNewPM || !isNotSharedDraft) {
      return false;
    }

    // list_type: group may return an array or a comma-separated string,
    // and may store group IDs or names depending on Discourse version
    const rawSetting = settings.restrict_to_groups;
    const restrictToGroups = (
      Array.isArray(rawSetting)
        ? rawSetting
        : (rawSetting?.split(",") ?? [])
    )
      .map((g) => String(g).trim())
      .filter(Boolean);

    if (restrictToGroups.length > 0) {
      const userGroups = this.currentUser.groups ?? [];
      const inGroup = restrictToGroups.some((g) => {
        const asId = parseInt(g, 10);
        return userGroups.some(
          (ug) =>
            ug.name.toLowerCase() === g.toLowerCase() ||
            (!isNaN(asId) && ug.id === asId)
        );
      });
      if (!inGroup) {
        return false;
      }
    }

    // If whisper_only is enabled, only show the button when actively whispering
    if (settings.whisper_only && !this.composer.isWhispering) {
      return false;
    }

    return true;
  }

  get icon() {
    return this.composer.isWhispering ? "far-eye-slash" : "far-eye";
  }

  get translatedLabel() {
    if (this.composer.isWhispering) {
      return i18n(themePrefix("whispering"));
    } else {
      return i18n(themePrefix("public_reply"));
    }
  }

  @action
  toggleWhisper() {
    this.composer.toggleWhisper();
  }

  <template>
    {{#if this.showWarning}}
      <DButton
        @preventFocus={{true}}
        @action={{this.toggleWhisper}}
        @icon={{this.icon}}
        class={{concatClass
          "whisper-hint"
          (if this.composer.isWhispering "whispering" "public")
        }}
        @translatedLabel={{this.translatedLabel}}
      />
    {{/if}}
  </template>
}
