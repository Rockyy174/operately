import React, { useState } from "react";
import { useNavigate } from "react-router-dom";

import { ResourceHub, useCreateResourceHubFolder } from "@/models/resourceHubs";

import { IconFile, IconFolder, IconUpload } from "@tabler/icons-react";
import { OptionsButton } from "@/components/Buttons";
import Modal from "@/components/Modal";
import Forms from "@/components/Forms";
import { Paths } from "@/routes/paths";

interface Props {
  resourceHub: ResourceHub;
  refresh: () => void;
  folderId?: string;
}

export function AddFilesButtonAndForms({ resourceHub, refresh, folderId }: Props) {
  const navigate = useNavigate();
  const [showAddFolder, setShowAddFolder] = useState(false);

  const toggleShowAddFolder = () => setShowAddFolder(!showAddFolder);
  const navigateToNewDocument = () => navigate(Paths.resourceHubNewDocumentPath(resourceHub.id!, folderId));

  return (
    <>
      <div className="w-min mt-2">
        <OptionsButton
          align="start"
          options={[
            { icon: IconFile, label: "Write a new document", action: navigateToNewDocument, testId: "new-document" },
            { icon: IconFolder, label: "Create a new folder", action: toggleShowAddFolder, testId: "new-folder" },
            { icon: IconUpload, label: "Upload files", action: () => {}, testId: "upload-files" },
          ]}
          testId="add-options"
        />
      </div>

      <AddFolderModal
        resourceHub={resourceHub}
        showForm={showAddFolder}
        toggleForm={toggleShowAddFolder}
        refresh={refresh}
        folderId={folderId}
      />
    </>
  );
}

interface FormProps {
  showForm: boolean;
  toggleForm: () => void;
  refresh: () => void;
  resourceHub: ResourceHub;
  folderId?: string;
}

function AddFolderModal({ resourceHub, showForm, toggleForm, refresh, folderId }: FormProps) {
  const [post] = useCreateResourceHubFolder();

  const form = Forms.useForm({
    fields: {
      name: "",
      description: null,
    },
    validate: (addError) => {
      if (!form.values.name) {
        addError("name", "Name is required");
      }
    },
    cancel: toggleForm,
    submit: async () => {
      await post({
        resourceHubId: resourceHub.id,
        folderId: folderId,
        name: form.values.name,
        description: JSON.stringify(form.values.description),
      });
      refresh();
      toggleForm();
      form.actions.reset();
    },
  });

  return (
    <Modal title="New folder" isOpen={showForm} hideModal={toggleForm}>
      <Forms.Form form={form}>
        <Forms.FieldGroup>
          <Forms.TextInput label="Name" field="name" />
          <Forms.RichTextArea
            label="Description"
            field="description"
            mentionSearchScope={{ type: "none" }}
            placeholder="Description..."
          />
        </Forms.FieldGroup>

        <Forms.Submit cancelText="Cancel" />
      </Forms.Form>
    </Modal>
  );
}