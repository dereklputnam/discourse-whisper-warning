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

    // If groups specified, user must be in at least one.
    // list_type: group may store IDs or names — check both.
    const rawGroups = settings.restrict_to_groups;
    const restrictToGroups = (
      Array.isArray(rawGroups) ? rawGroups : (rawGroups?.split(",") ?? [])
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

    // If categories specified, topic must be in at least one.
    // list_type: category may store IDs or slugs — check both.
    const rawCategories = settings.restrict_to_categories;
    const restrictToCategories = (
      Array.isArray(rawCategories)
        ? rawCategories
        : (rawCategories?.split(",") ?? [])
    )
      .map((c) => String(c).trim())
      .filter(Boolean);

    if (restrictToCategories.length > 0) {
      const category = this.args.outletArgs.model.category;
      if (!category) {
        return false;
      }
      const catId = category.get ? category.get("id") : category.id;
      const catSlug = category.get ? category.get("slug") : category.slug;
      const inCategory = restrictToCategories.some((c) => {
        const asId = parseInt(c, 10);
        return (
          (catSlug && catSlug.toLowerCase() === c.toLowerCase()) ||
          (!isNaN(asId) && catId === asId)
        );
      });
      if (!inCategory) {
        return false;
      }
    }

    // If whisper_only is enabled, only show when actively whispering
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