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
    // checks if the current user is replying in a group PM
    const allowedGroups =
      this.args.outletArgs.model.topic?.get("allowedGroups");
    // to check if reply is in a PM
    const isPM =
      this.args.outletArgs.model.topic?.get("archetype") === "private_message";
    // checks to make sure user is in group that PM is added to
    const isInInboxGroup = allowedGroups
      ? this.currentUser.groups?.filter((group) => {
          for (let allowedGroup of allowedGroups) {
            if (group.name === allowedGroup.name) {
              return group;
            }
          }
        }).length > 0
      : false;

    const readRestricted =
      this.args.outletArgs.model.category?.get("read_restricted");
    const canWhisper = this.composer.showWhisperToggle;
    const isNotNewTopic =
      this.args.outletArgs.model.get("action") !== "createTopic";
    const isNotNewPM =
      this.args.outletArgs.model.get("action") !== "privateMessage";
    const isNotSharedDraft =
      this.args.outletArgs.model.get("action") !== "createSharedDraft";

    const contextMatches =
      (canWhisper &&
        isNotNewTopic &&
        isNotNewPM &&
        isNotSharedDraft &&
        readRestricted) ||
      (isPM && isInInboxGroup && canWhisper);

    if (!contextMatches) {
      return false;
    }

    // If a group restriction is set, only show for members of that group
    const restrictToGroup = settings.restrict_to_group?.trim();
    if (restrictToGroup) {
      const inGroup = this.currentUser.groups?.some(
        (g) => g.name === restrictToGroup
      );
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
